import SwiftUI

struct LabelsView: View {
    @EnvironmentObject private var serviceStore: ServiceStore
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var preferences: PreferencesStore
    @Environment(\.dismiss) private var dismiss
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var torrentName: String = ""
    @State private var labels: [String] = []
    @State private var newLabel: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
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
                if labels.isEmpty {
                    Text("No labels yet.")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(labels, id: \.self) { label in
                        HStack {
                            Text(label)
                            Spacer()
                            Button {
                                removeLabel(label)
                            } label: {
                                Image(systemName: "trash")
                            }
                            .buttonStyle(.bordered)
                            .help("Remove label")
                        }
                    }
                }
            }

            HStack(spacing: 8) {
                TextField("New label", text: $newLabel)
                    .textFieldStyle(.roundedBorder)
                Button("Add") { addLabel() }
                    .buttonStyle(.borderedProminent)
                    .disabled(newLabel.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }

            Spacer()

            HStack {
                Spacer()
                Button("Cancel") { dismiss() }
                Button("OK") { Task { await save() } }
                    .buttonStyle(.borderedProminent)
            }
        }
        .padding(20)
        .frame(minWidth: 460, minHeight: 420)
        .onAppear(perform: load)
        .onChange(of: appState.labelsTorrentID) { _, _ in load() }
    }

    private func load() {
        guard let service = selectedService else {
            errorMessage = "Select a service to edit labels."
            return
        }
        guard let torrentID = appState.labelsTorrentID else {
            errorMessage = "Select a torrent to edit labels."
            return
        }

        errorMessage = nil
        isLoading = true
        labels = []

        Task {
            defer { isLoading = false }
            do {
                let client = TransmissionRPCClient(
                    config: service,
                    allowInsecureTLS: preferences.allowInsecureTLS
                )
                let response: TorrentLabelsResponseArguments = try await client.request(
                    method: "torrent-get",
                    arguments: TorrentGetArguments(fields: ["id", "name", "labels"], ids: [torrentID])
                )
                guard let info = response.torrents.first else {
                    errorMessage = "Torrent data not found."
                    return
                }
                torrentName = info.name
                labels = info.labels.sorted()
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    private func save() async {
        guard let service = selectedService else { return }
        guard let torrentID = appState.labelsTorrentID else { return }

        isLoading = true
        defer { isLoading = false }

        do {
            let client = TransmissionRPCClient(
                config: service,
                allowInsecureTLS: preferences.allowInsecureTLS
            )
            let args = TorrentSetLabelsArguments(ids: [torrentID], labels: labels)
            let _: EmptyResponse = try await client.request(method: "torrent-set", arguments: args)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func addLabel() {
        let trimmed = newLabel.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        if !labels.contains(trimmed) {
            labels.append(trimmed)
            labels.sort()
        }
        newLabel = ""
    }

    private func removeLabel(_ label: String) {
        labels.removeAll { $0 == label }
    }

    private var selectedService: ServiceConfig? {
        let configured = serviceStore.service(id: appState.selectedServiceID)
        if let configured {
            return configured
        }
        return serviceStore.services.first
    }
}
