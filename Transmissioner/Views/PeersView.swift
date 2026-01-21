import SwiftUI

struct PeersView: View {
    @EnvironmentObject private var serviceStore: ServiceStore
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var preferences: PreferencesStore
    @Environment(\.dismiss) private var dismiss
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var torrentName: String = ""
    @State private var peers: [TorrentPeer] = []
    @State private var peersFrom: [String: Int] = [:]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Peers")
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

            if !peersFrom.isEmpty {
                Text(sourceSummary)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            List {
                ForEach(peers) { peer in
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(peer.address)
                                .font(.headline)
                            Text(peer.clientName)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 4) {
                            Text(Formatters.percentString(peer.progress))
                                .monospacedDigit()
                            Text("\(Formatters.rateString(peer.rateToClient)) ↓  \(Formatters.rateString(peer.rateToPeer)) ↑")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .monospacedDigit()
                        }

                        Text(peer.flagStr)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(width: 60, alignment: .trailing)
                    }
                }
            }

            HStack {
                Spacer()
                Button("Close") { dismiss() }
            }
        }
        .padding(20)
        .frame(minWidth: 640, minHeight: 520)
        .onAppear(perform: load)
        .onChange(of: appState.peersTorrentID) { _, _ in load() }
    }

    private func load() {
        guard let service = selectedService else {
            errorMessage = "Select a service to view peers."
            return
        }
        guard let torrentID = appState.peersTorrentID else {
            errorMessage = "Select a torrent to view peers."
            return
        }

        errorMessage = nil
        isLoading = true
        peers = []
        peersFrom = [:]

        Task {
            defer { isLoading = false }
            do {
                let client = TransmissionRPCClient(
                    config: service,
                    allowInsecureTLS: preferences.allowInsecureTLS
                )
                let response: TorrentPeersResponseArguments = try await client.request(
                    method: "torrent-get",
                    arguments: TorrentGetArguments(
                        fields: ["id", "name", "peers", "peersFrom"],
                        ids: [torrentID]
                    )
                )
                guard let info = response.torrents.first else {
                    errorMessage = "Torrent data not found."
                    return
                }
                torrentName = info.name
                peers = info.peers
                peersFrom = info.peersFrom
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    private var sourceSummary: String {
        let mapping: [(String, String)] = [
            ("fromCache", "Cache"),
            ("fromDht", "DHT"),
            ("fromIncoming", "Incoming"),
            ("fromLpd", "LPD"),
            ("fromLtep", "LTEP"),
            ("fromPex", "PEX"),
            ("fromTracker", "Tracker")
        ]
        let parts = mapping.compactMap { key, label -> String? in
            guard let value = peersFrom[key], value > 0 else { return nil }
            return "\(label): \(value)"
        }
        return parts.isEmpty ? "" : "Sources: " + parts.joined(separator: " • ")
    }

    private var selectedService: ServiceConfig? {
        let configured = serviceStore.service(id: appState.selectedServiceID)
        if let configured {
            return configured
        }
        return serviceStore.services.first
    }
}
