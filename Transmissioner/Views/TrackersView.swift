import SwiftUI

struct TrackersView: View {
    @EnvironmentObject private var serviceStore: ServiceStore
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var torrentName: String = ""
    @State private var trackers: [TorrentTracker] = []
    @State private var newTrackerURL: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Trackers")
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
                ForEach(trackers) { tracker in
                    HStack(spacing: 12) {
                        Text(tracker.announce)
                            .lineLimit(1)
                            .truncationMode(.middle)
                        Spacer()
                        Button {
                            Task { await removeTracker(tracker.id) }
                        } label: {
                            Image(systemName: "trash")
                        }
                        .buttonStyle(.bordered)
                        .help("Remove tracker")
                    }
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Add tracker")
                    .font(.headline)
                HStack(spacing: 8) {
                    TextField("https://tracker.example/announce", text: $newTrackerURL)
                        .textFieldStyle(.roundedBorder)
                    Button("Add") { Task { await addTracker() } }
                        .buttonStyle(.borderedProminent)
                        .disabled(newTrackerURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }

            HStack {
                Spacer()
                Button("Close") { dismiss() }
            }
        }
        .padding(20)
        .frame(minWidth: 600, minHeight: 520)
        .onAppear(perform: load)
        .onChange(of: appState.trackersTorrentID) { _, _ in load() }
    }

    private func load() {
        guard let service = selectedService else {
            errorMessage = "Select a service to edit trackers."
            return
        }
        guard let torrentID = appState.trackersTorrentID else {
            errorMessage = "Select a torrent to edit trackers."
            return
        }

        errorMessage = nil
        isLoading = true
        trackers = []

        Task {
            defer { isLoading = false }
            do {
                let client = TransmissionRPCClient(config: service)
                let response: TorrentGetTrackersResponseArguments = try await client.request(
                    method: "torrent-get",
                    arguments: TorrentGetArguments(fields: ["id", "name", "trackers"], ids: [torrentID])
                )
                guard let info = response.torrents.first else {
                    errorMessage = "Torrent data not found."
                    return
                }
                torrentName = info.name
                trackers = info.trackers
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    private func addTracker() async {
        guard let service = selectedService else { return }
        guard let torrentID = appState.trackersTorrentID else { return }
        let trimmed = newTrackerURL.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        isLoading = true
        defer { isLoading = false }

        do {
            let client = TransmissionRPCClient(config: service)
            let args = TorrentSetTrackersArguments(ids: [torrentID], trackerAdd: [trimmed], trackerRemove: nil)
            let _: EmptyResponse = try await client.request(method: "torrent-set", arguments: args)
            newTrackerURL = ""
            load()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func removeTracker(_ trackerID: Int) async {
        guard let service = selectedService else { return }
        guard let torrentID = appState.trackersTorrentID else { return }

        isLoading = true
        defer { isLoading = false }

        do {
            let client = TransmissionRPCClient(config: service)
            let args = TorrentSetTrackersArguments(ids: [torrentID], trackerAdd: nil, trackerRemove: [trackerID])
            let _: EmptyResponse = try await client.request(method: "torrent-set", arguments: args)
            load()
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
