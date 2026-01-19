import SwiftUI

struct SessionSettingsView: View {
    @EnvironmentObject private var serviceStore: ServiceStore
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var encryption: EncryptionMode = .preferred
    @State private var peerLimitGlobal: Int = 200
    @State private var peerLimitPerTorrent: Int = 50

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Session Settings")
                    .font(.title2.weight(.semibold))
                Spacer()
                if isLoading {
                    ProgressView()
                        .controlSize(.small)
                }
            }

            if let errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundColor(.red)
            }

            Form {
                Section("Encryption") {
                    Picker("Mode", selection: $encryption) {
                        ForEach(EncryptionMode.allCases) { mode in
                            Text(mode.label).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("Peer Limits") {
                    Stepper(value: $peerLimitGlobal, in: 1...5_000) {
                        LabeledContent("Global", value: "\(peerLimitGlobal)")
                            .monospacedDigit()
                    }
                    Stepper(value: $peerLimitPerTorrent, in: 1...1_000) {
                        LabeledContent("Per torrent", value: "\(peerLimitPerTorrent)")
                            .monospacedDigit()
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
        .frame(minWidth: 440)
        .onAppear(perform: load)
        .onChange(of: appState.selectedServiceID) { _, _ in load() }
    }

    private func load() {
        guard let service = selectedService else {
            errorMessage = "Select a service to edit session settings."
            return
        }

        errorMessage = nil
        isLoading = true

        Task {
            defer { isLoading = false }
            do {
                let client = TransmissionRPCClient(config: service)
                let response: SessionGetResponseArguments = try await client.request(
                    method: "session-get",
                    arguments: SessionGetArguments()
                )
                encryption = EncryptionMode(response.encryption)
                peerLimitGlobal = max(1, response.peerLimitGlobal ?? peerLimitGlobal)
                peerLimitPerTorrent = max(1, response.peerLimitPerTorrent ?? peerLimitPerTorrent)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    private func save() async {
        guard let service = selectedService else { return }

        isLoading = true
        defer { isLoading = false }

        do {
            let client = TransmissionRPCClient(config: service)
            let args = SessionSetPeerLimitsArguments(
                encryption: encryption.rawValue,
                peerLimitGlobal: peerLimitGlobal,
                peerLimitPerTorrent: peerLimitPerTorrent
            )
            let _: EmptyResponse = try await client.request(method: "session-set", arguments: args)
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

private enum EncryptionMode: String, CaseIterable, Identifiable {
    case required
    case preferred
    case tolerated

    init(_ rawValue: String?) {
        switch rawValue {
        case "required": self = .required
        case "tolerated": self = .tolerated
        default: self = .preferred
        }
    }

    var id: String { rawValue }

    var label: String {
        switch self {
        case .required: return "Required"
        case .preferred: return "Preferred"
        case .tolerated: return "Tolerated"
        }
    }
}
