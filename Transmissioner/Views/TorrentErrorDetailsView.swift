import SwiftUI

struct TorrentErrorDetailsView: View {
    @EnvironmentObject private var serviceStore: ServiceStore
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var info: TorrentErrorInfo?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Error Details")
                    .font(.title2.weight(.semibold))
                Spacer()
                if isLoading {
                    ProgressView()
                        .controlSize(.small)
                }
            }

            if let name = info?.name {
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
                LabeledContent("Error code") {
                    Text(errorCodeString(info?.error))
                        .monospacedDigit()
                }
                LabeledContent("Error message") {
                    Text(info?.errorString ?? "—")
                        .foregroundColor(.red)
                        .lineLimit(3)
                }
                LabeledContent("Last activity") {
                    Text(dateString(info?.activityDate))
                }
            }

            HStack(spacing: 8) {
                Button("Reannounce") { Task { await reannounce() } }
                Button("Verify") { Task { await verify() } }
                Button("Start") { Task { await start() } }
                Spacer()
                Button("Close") { dismiss() }
            }
        }
        .padding(20)
        .frame(minWidth: 480)
        .onAppear(perform: load)
        .onChange(of: appState.errorDetailsTorrentID) { _, _ in load() }
    }

    private func load() {
        guard let service = selectedService else {
            errorMessage = "Select a service to view error details."
            return
        }
        guard let torrentID = appState.errorDetailsTorrentID else {
            errorMessage = "Select a torrent to view error details."
            return
        }

        errorMessage = nil
        isLoading = true
        info = nil

        Task {
            defer { isLoading = false }
            do {
                let client = TransmissionRPCClient(config: service)
                let response: TorrentErrorResponseArguments = try await client.request(
                    method: "torrent-get",
                    arguments: TorrentGetArguments(
                        fields: ["id", "name", "error", "errorString", "activityDate"],
                        ids: [torrentID]
                    )
                )
                info = response.torrents.first
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    private func reannounce() async {
        await runAction(method: "torrent-reannounce")
    }

    private func verify() async {
        await runAction(method: "torrent-verify")
    }

    private func start() async {
        await runAction(method: "torrent-start")
    }

    private func runAction(method: String) async {
        guard let service = selectedService else { return }
        guard let torrentID = appState.errorDetailsTorrentID else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            let client = TransmissionRPCClient(config: service)
            let _: EmptyResponse = try await client.request(
                method: method,
                arguments: TorrentActionArguments(ids: [torrentID])
            )
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

    private func errorCodeString(_ code: Int?) -> String {
        guard let code else { return "—" }
        return "\(code)"
    }

    private func dateString(_ timestamp: Int?) -> String {
        guard let timestamp, timestamp > 0 else { return "—" }
        let date = Date(timeIntervalSince1970: TimeInterval(timestamp))
        return date.formatted(date: .abbreviated, time: .shortened)
    }
}
