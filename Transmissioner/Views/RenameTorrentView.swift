import SwiftUI

struct RenameTorrentView: View {
    @EnvironmentObject private var serviceStore: ServiceStore
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var preferences: PreferencesStore
    @Environment(\.dismiss) private var dismiss
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var currentName: String = ""
    @State private var newName: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Rename Torrent")
                    .font(.title2.weight(.semibold))
                Spacer()
                if isLoading {
                    ProgressView()
                        .controlSize(.small)
                }
            }

            if !currentName.isEmpty {
                Text(currentName)
                    .font(.headline)
                    .lineLimit(2)
            }

            if let errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundColor(.red)
            }

            TextField("New name", text: $newName)
                .textFieldStyle(.roundedBorder)

            HStack {
                Spacer()
                Button("Cancel") { dismiss() }
                Button("Rename") { Task { await rename() } }
                    .buttonStyle(.borderedProminent)
                    .disabled(newName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || newName == currentName)
            }
        }
        .padding(20)
        .frame(minWidth: 420)
        .onAppear(perform: load)
        .onChange(of: appState.renameTorrentID) { _, _ in load() }
    }

    private func load() {
        guard let service = selectedService else {
            errorMessage = "Select a service to rename torrents."
            return
        }
        guard let torrentID = appState.renameTorrentID else {
            errorMessage = "Select a torrent to rename."
            return
        }

        errorMessage = nil
        isLoading = true
        currentName = ""
        newName = ""

        Task {
            defer { isLoading = false }
            do {
                let client = TransmissionRPCClient(
                    config: service,
                    allowInsecureTLS: preferences.allowInsecureTLS
                )
                let response: TorrentGetResponseArguments = try await client.request(
                    method: "torrent-get",
                    arguments: TorrentGetArguments(fields: ["id", "name"], ids: [torrentID])
                )
                guard let info = response.torrents.first else {
                    errorMessage = "Torrent data not found."
                    return
                }
                currentName = info.name
                newName = info.name
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    private func rename() async {
        guard let service = selectedService else { return }
        guard let torrentID = appState.renameTorrentID else { return }
        let trimmed = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        isLoading = true
        defer { isLoading = false }

        do {
            let client = TransmissionRPCClient(
                config: service,
                allowInsecureTLS: preferences.allowInsecureTLS
            )
            let args = TorrentRenameArguments(ids: [torrentID], path: currentName, name: trimmed)
            let _: TorrentRenameResponseArguments = try await client.request(
                method: "torrent-rename-path",
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
