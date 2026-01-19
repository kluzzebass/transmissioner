import SwiftUI

struct TorrentListView: View {
    @ObservedObject var viewModel: TorrentListViewModel
    let torrents: [TorrentInfo]
    let compact: Bool
    let onSetLocation: (TorrentInfo) -> Void
    let onFileSelection: (TorrentInfo) -> Void
    let onTrackers: (TorrentInfo) -> Void
    let onStats: (TorrentInfo) -> Void
    let onPeers: (TorrentInfo) -> Void
    let onSeedingLimits: (TorrentInfo) -> Void
    let onRename: (TorrentInfo) -> Void
    let onLabels: (TorrentInfo) -> Void
    @State private var pendingRemoval: PendingRemoval?

    var body: some View {
        ZStack {
            VStack(spacing: 8) {
                if viewModel.isLoading && viewModel.torrents.isEmpty {
                    HStack(spacing: 8) {
                        ProgressView()
                            .controlSize(.small)
                        Text("Connecting to Transmission…")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                if let lastError = viewModel.lastError {
                    Text(lastError)
                        .foregroundColor(.red)
                        .font(.caption)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                List {
                    ForEach(torrents) { torrent in
                        TorrentRowView(
                            torrent: torrent,
                            globalSeedRatioLimit: viewModel.sessionSeedRatioLimit,
                            globalSeedRatioLimited: viewModel.sessionSeedRatioLimited,
                            onToggle: { Task { await toggle(torrent) } },
                            onRequestRemove: { pendingRemoval = PendingRemoval(torrent: torrent, deleteData: false) },
                            onRequestRemoveWithData: { pendingRemoval = PendingRemoval(torrent: torrent, deleteData: true) },
                            onVerify: { Task { await viewModel.verify(ids: [torrent.id]) } },
                            onReannounce: { Task { await viewModel.reannounce(ids: [torrent.id]) } },
                            onQueueMoveTop: { Task { await viewModel.moveQueueTop(ids: [torrent.id]) } },
                            onQueueMoveUp: { Task { await viewModel.moveQueueUp(ids: [torrent.id]) } },
                            onQueueMoveDown: { Task { await viewModel.moveQueueDown(ids: [torrent.id]) } },
                            onQueueMoveBottom: { Task { await viewModel.moveQueueBottom(ids: [torrent.id]) } },
                            onSetPriorityLow: { Task { await viewModel.setBandwidthPriority(ids: [torrent.id], priority: -1) } },
                            onSetPriorityNormal: { Task { await viewModel.setBandwidthPriority(ids: [torrent.id], priority: 0) } },
                            onSetPriorityHigh: { Task { await viewModel.setBandwidthPriority(ids: [torrent.id], priority: 1) } },
                            onSetLocation: { onSetLocation(torrent) },
                            onFileSelection: { onFileSelection(torrent) },
                            onTrackers: { onTrackers(torrent) },
                            onStats: { onStats(torrent) },
                            onPeers: { onPeers(torrent) },
                            onSeedingLimits: { onSeedingLimits(torrent) },
                            onRename: { onRename(torrent) },
                            onLabels: { onLabels(torrent) }
                        )
                        .listRowInsets(EdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8))
                        .id(torrent.id)
                    }
                }
                .listStyle(.inset)
                .transaction { transaction in
                    transaction.disablesAnimations = true
                }
            }

            if viewModel.isLoading && viewModel.torrents.isEmpty {
                VStack(spacing: 8) {
                    ProgressView()
                    Text("Loading torrents…")
                        .font(.callout)
                        .foregroundColor(.secondary)
                }
            }

        if let pending = pendingRemoval {
                Color.black.opacity(0.25)
                    .ignoresSafeArea()
                    .onTapGesture {
                    pendingRemoval = nil
                    }

                VStack(spacing: 12) {
                Text(pending.deleteData ? "Remove & Delete Data" : "Remove Torrent")
                        .font(.headline)
                Text(pending.deleteData
                     ? "This will remove “\(pending.torrent.name)” and delete its local data."
                     : "This will remove “\(pending.torrent.name)” from Transmission.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)

                    HStack {
                        Button("Cancel") {
                        pendingRemoval = nil
                        }
                        Spacer()
                    Button(pending.deleteData ? "Delete Data" : "Remove") {
                        pendingRemoval = nil
                        Task { await viewModel.remove(ids: [pending.torrent.id], deleteData: pending.deleteData) }
                        }
                    .buttonStyle(.borderedProminent)
                    .tint(pending.deleteData ? .red : .accentColor)
                    }
                }
                .padding(16)
                .frame(maxWidth: .infinity)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )
                .shadow(radius: 10)
            .padding(20)
            }
        }
        .frame(minHeight: compact ? 220 : 320)
    }

    private func toggle(_ torrent: TorrentInfo) async {
        if torrent.isActive {
            await viewModel.stop(ids: [torrent.id])
        } else {
            await viewModel.start(ids: [torrent.id])
        }
    }

    private func remove(_ torrent: TorrentInfo) async {
        await viewModel.remove(ids: [torrent.id], deleteData: false)
    }

    private struct PendingRemoval: Identifiable {
        let id = UUID()
        let torrent: TorrentInfo
        let deleteData: Bool
    }

}
