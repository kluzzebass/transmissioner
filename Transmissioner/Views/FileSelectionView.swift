import SwiftUI

struct FileSelectionView: View {
    @EnvironmentObject private var serviceStore: ServiceStore
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var torrentName: String = ""
    @State private var rows: [FileRow] = []

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("File Selection")
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

            List {
                ForEach($rows) { $row in
                    HStack(spacing: 12) {
                        Toggle("", isOn: $row.wanted)
                            .labelsHidden()

                        VStack(alignment: .leading, spacing: 4) {
                            Text(row.name)
                                .lineLimit(1)
                            Text(Formatters.sizeString(row.length))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        Picker("Priority", selection: $row.priority) {
                            ForEach(FilePriority.allCases, id: \.self) { priority in
                                Text(priority.label).tag(priority)
                            }
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 220)
                    }
                }
            }

            HStack {
                Spacer()
                Button("Cancel") { dismiss() }
                Button("OK") { Task { await save() } }
                    .buttonStyle(.borderedProminent)
                    .disabled(rows.isEmpty)
            }
        }
        .padding(20)
        .frame(minWidth: 600, minHeight: 520)
        .onAppear(perform: load)
        .onChange(of: appState.fileSelectionTorrentID) { _, _ in
            load()
        }
    }

    private func load() {
        guard let service = selectedService else {
            errorMessage = "Select a service to edit files."
            return
        }
        guard let torrentID = appState.fileSelectionTorrentID else {
            errorMessage = "Select a torrent to edit files."
            return
        }

        errorMessage = nil
        isLoading = true
        rows = []

        Task {
            defer { isLoading = false }
            do {
                let client = TransmissionRPCClient(config: service)
                let response: TorrentGetFilesResponseArguments = try await client.request(
                    method: "torrent-get",
                    arguments: TorrentGetArguments(fields: ["id", "name", "files", "fileStats"], ids: [torrentID])
                )
                guard let info = response.torrents.first else {
                    errorMessage = "Torrent data not found."
                    return
                }
                torrentName = info.name
                rows = zip(info.files.indices, info.files).map { index, file in
                    let stat = info.fileStats[index]
                    return FileRow(
                        id: index,
                        name: file.name,
                        length: file.length,
                        wanted: stat.wanted,
                        priority: FilePriority(stat.priority)
                    )
                }
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    private func save() async {
        guard let service = selectedService else { return }
        guard let torrentID = appState.fileSelectionTorrentID else { return }

        let wanted = rows.filter { $0.wanted }.map { $0.id }
        let unwanted = rows.filter { !$0.wanted }.map { $0.id }
        let high = rows.filter { $0.priority == .high }.map { $0.id }
        let normal = rows.filter { $0.priority == .normal }.map { $0.id }
        let low = rows.filter { $0.priority == .low }.map { $0.id }

        isLoading = true
        defer { isLoading = false }

        do {
            let client = TransmissionRPCClient(config: service)
            let args = TorrentSetFilesArguments(
                ids: [torrentID],
                filesWanted: wanted,
                filesUnwanted: unwanted,
                priorityHigh: high,
                priorityNormal: normal,
                priorityLow: low
            )
            let _: EmptyResponse = try await client.request(
                method: "torrent-set",
                arguments: args
            )
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

private struct FileRow: Identifiable {
    let id: Int
    let name: String
    let length: Int
    var wanted: Bool
    var priority: FilePriority
}

private enum FilePriority: Int, CaseIterable {
    case low = -1
    case normal = 0
    case high = 1

    init(_ rawValue: Int) {
        switch rawValue {
        case 1: self = .high
        case -1: self = .low
        default: self = .normal
        }
    }

    var label: String {
        switch self {
        case .low: return "Low"
        case .normal: return "Normal"
        case .high: return "High"
        }
    }
}
