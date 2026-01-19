import SwiftUI

struct SeedingLimitsView: View {
    @EnvironmentObject private var serviceStore: ServiceStore
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var torrentName: String = ""
    @State private var ratioMode: SeedLimitMode = .global
    @State private var ratioLimit: Double = 2.0
    @State private var idleMode: SeedLimitMode = .global
    @State private var idleMinutes: Int = 30

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Seeding Limits")
                    .font(.title2.weight(.semibold))
                Spacer()
                if isLoading {
                    ProgressView()
                        .controlSize(.small)
                }
            }

            if !torrentName.isEmpty {
                Text(torrentName)
                    .font(.headline)
                    .lineLimit(2)
            }

            if let errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundColor(.red)
            }

            Form {
                Section("Seed Ratio") {
                    Picker("Mode", selection: $ratioMode) {
                        ForEach(SeedLimitMode.allCases) { mode in
                            Text(mode.label).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)

                    HStack {
                        Text("Limit")
                            .foregroundColor(.secondary)
                        Spacer()
                        TextField("", value: $ratioLimit, formatter: NumberFormatter.decimal)
                            .frame(width: 80)
                            .textFieldStyle(.roundedBorder)
                            .disabled(ratioMode != .custom)
                    }
                }

                Section("Idle Seeding") {
                    Picker("Mode", selection: $idleMode) {
                        ForEach(SeedLimitMode.allCases) { mode in
                            Text(mode.label).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)

                    HStack {
                        Text("Limit (minutes)")
                            .foregroundColor(.secondary)
                        Spacer()
                        Stepper(value: $idleMinutes, in: 1...10_080, step: 5) {
                            Text("\(idleMinutes)")
                                .monospacedDigit()
                        }
                        .disabled(idleMode != .custom)
                    }
                }
            }

            HStack {
                Spacer()
                Button("Cancel") { dismiss() }
                Button("OK") { Task { await save() } }
                    .buttonStyle(.borderedProminent)
            }
        }
        .padding(20)
        .frame(minWidth: 480)
        .onAppear(perform: load)
        .onChange(of: appState.seedingLimitsTorrentID) { _, _ in load() }
    }

    private func load() {
        guard let service = selectedService else {
            errorMessage = "Select a service to edit seeding limits."
            return
        }
        guard let torrentID = appState.seedingLimitsTorrentID else {
            errorMessage = "Select a torrent to edit seeding limits."
            return
        }

        errorMessage = nil
        isLoading = true

        Task {
            defer { isLoading = false }
            do {
                let client = TransmissionRPCClient(config: service)
                let response: TorrentSeedLimitsResponseArguments = try await client.request(
                    method: "torrent-get",
                    arguments: TorrentGetArguments(
                        fields: ["id", "name", "seedRatioMode", "seedRatioLimit", "seedIdleMode", "seedIdleLimit"],
                        ids: [torrentID]
                    )
                )
                guard let info = response.torrents.first else {
                    errorMessage = "Torrent data not found."
                    return
                }
                torrentName = info.name
                ratioMode = SeedLimitMode(info.seedRatioMode)
                ratioLimit = max(0, info.seedRatioLimit ?? 2.0)
                idleMode = SeedLimitMode(info.seedIdleMode)
                idleMinutes = max(1, info.seedIdleLimit ?? 30)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    private func save() async {
        guard let service = selectedService else { return }
        guard let torrentID = appState.seedingLimitsTorrentID else { return }

        isLoading = true
        defer { isLoading = false }

        do {
            let client = TransmissionRPCClient(config: service)
            let args = TorrentSetSeedLimitsArguments(
                ids: [torrentID],
                seedRatioLimit: ratioMode == .custom ? ratioLimit : nil,
                seedRatioMode: ratioMode.rawValue,
                seedIdleLimit: idleMode == .custom ? idleMinutes : nil,
                seedIdleMode: idleMode.rawValue
            )
            let _: EmptyResponse = try await client.request(method: "torrent-set", arguments: args)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private var selectedService: ServiceConfig? {
        let configured = serviceStore.service(id: appState.selectedServiceID)
        if let configured {
            return configured
        }
        return serviceStore.services.first
    }
}

private enum SeedLimitMode: Int, CaseIterable, Identifiable {
    case global = 0
    case custom = 1
    case unlimited = 2

    init(_ rawValue: Int) {
        switch rawValue {
        case 1: self = .custom
        case 2: self = .unlimited
        default: self = .global
        }
    }

    var id: Int { rawValue }

    var label: String {
        switch self {
        case .global: return "Global"
        case .custom: return "Custom"
        case .unlimited: return "Unlimited"
        }
    }
}

private extension NumberFormatter {
    static var decimal: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        return formatter
    }
}
