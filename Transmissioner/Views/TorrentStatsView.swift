import SwiftUI

struct TorrentStatsView: View {
    @EnvironmentObject private var serviceStore: ServiceStore
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var stats: TorrentStatsInfo?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Torrent Stats")
                    .font(.title2.weight(.semibold))
                Spacer()
                if isLoading {
                    ProgressView()
                        .controlSize(.small)
                }
            }

            if let name = stats?.name {
                Text(name)
                    .font(.headline)
                    .lineLimit(2)
            }

            if let errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundColor(.red)
            }

            Form {
                LabeledContent("Total size") {
                    Text(sizeString(stats?.totalSize))
                }
                LabeledContent("Downloaded") {
                    Text(sizeString(stats?.downloadedEver))
                }
                LabeledContent("Uploaded") {
                    Text(sizeString(stats?.uploadedEver))
                }
                LabeledContent("Corrupt") {
                    Text(sizeString(stats?.corruptEver))
                }

                Divider()

                LabeledContent("Added") {
                    Text(dateString(stats?.addedDate))
                }
                LabeledContent("Started") {
                    Text(dateString(stats?.startDate))
                }
                LabeledContent("Completed") {
                    Text(dateString(stats?.doneDate))
                }
                LabeledContent("Last activity") {
                    Text(dateString(stats?.activityDate))
                }

                Divider()

                LabeledContent("Time downloading") {
                    Text(durationString(stats?.secondsDownloading))
                }
                LabeledContent("Time seeding") {
                    Text(durationString(stats?.secondsSeeding))
                }

                Divider()

                LabeledContent("Peers connected") {
                    Text(intString(stats?.peersConnected))
                        .monospacedDigit()
                }
                LabeledContent("Peers sending to us") {
                    Text(intString(stats?.peersSendingToUs))
                        .monospacedDigit()
                }
                LabeledContent("Peers getting from us") {
                    Text(intString(stats?.peersGettingFromUs))
                        .monospacedDigit()
                }
            }

            HStack {
                Spacer()
                Button("Close") { dismiss() }
            }
        }
        .padding(20)
        .frame(minWidth: 460)
        .onAppear(perform: load)
        .onChange(of: appState.statsTorrentID) { _, _ in load() }
    }

    private func load() {
        guard let service = selectedService else {
            errorMessage = "Select a service to view torrent stats."
            return
        }
        guard let torrentID = appState.statsTorrentID else {
            errorMessage = "Select a torrent to view stats."
            return
        }

        errorMessage = nil
        isLoading = true
        stats = nil

        Task {
            defer { isLoading = false }
            do {
                let client = TransmissionRPCClient(config: service)
                let response: TorrentStatsResponseArguments = try await client.request(
                    method: "torrent-get",
                    arguments: TorrentGetArguments(
                        fields: [
                            "id",
                            "name",
                            "totalSize",
                            "downloadedEver",
                            "uploadedEver",
                            "corruptEver",
                            "addedDate",
                            "doneDate",
                            "activityDate",
                            "startDate",
                            "secondsDownloading",
                            "secondsSeeding",
                            "peersConnected",
                            "peersSendingToUs",
                            "peersGettingFromUs"
                        ],
                        ids: [torrentID]
                    )
                )
                stats = response.torrents.first
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    private var selectedService: ServiceConfig? {
        let configured = serviceStore.service(id: appState.selectedServiceID)
        if let configured {
            return configured
        }
        return serviceStore.services.first
    }

    private func dateString(_ timestamp: Int?) -> String {
        guard let timestamp, timestamp > 0 else { return "—" }
        let date = Date(timeIntervalSince1970: TimeInterval(timestamp))
        return date.formatted(date: .abbreviated, time: .shortened)
    }

    private func durationString(_ seconds: Int?) -> String {
        guard let seconds, seconds > 0 else { return "—" }
        return Formatters.etaString(seconds)
    }

    private func sizeString(_ bytes: Int?) -> String {
        guard let bytes else { return "—" }
        return Formatters.sizeString(bytes)
    }

    private func intString(_ value: Int?) -> String {
        guard let value else { return "—" }
        return "\(value)"
    }
}
