import SwiftUI

struct ServiceSectionView: View {
    let service: ServiceConfig
    @ObservedObject var viewModel: TorrentListViewModel
    @ObservedObject var filterState: FilterState
    let compact: Bool
    let onAddTorrent: () -> Void
    let onToggleAltSpeed: () -> Void
    let onToggle: (TorrentInfo) -> Void
    let onRequestRemove: (TorrentInfo, Bool) -> Void
    let onVerify: (TorrentInfo) -> Void
    let onReannounce: (TorrentInfo) -> Void
    let onQueueMoveTop: (TorrentInfo) -> Void
    let onQueueMoveUp: (TorrentInfo) -> Void
    let onQueueMoveDown: (TorrentInfo) -> Void
    let onQueueMoveBottom: (TorrentInfo) -> Void
    let onSetPriorityLow: (TorrentInfo) -> Void
    let onSetPriorityNormal: (TorrentInfo) -> Void
    let onSetPriorityHigh: (TorrentInfo) -> Void
    let onSetLocation: (TorrentInfo) -> Void
    let onFileSelection: (TorrentInfo) -> Void
    let onTrackers: (TorrentInfo) -> Void
    let onStats: (TorrentInfo) -> Void
    let onPeers: (TorrentInfo) -> Void
    let onSeedingLimits: (TorrentInfo) -> Void
    let onRename: (TorrentInfo) -> Void
    let onLabels: (TorrentInfo) -> Void
    let onErrorDetails: (TorrentInfo) -> Void
    let onRetryConnection: () -> Void

    var body: some View {
        let torrents = filteredTorrents(viewModel.torrents)
        return Section {
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

            if viewModel.isOffline {
                HStack(spacing: 8) {
                    Text("Offline")
                        .font(.caption)
                        .foregroundColor(.red)
                    if let lastError = viewModel.lastError {
                        Text(lastError)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                    Spacer()
                    Button("Retry Now") {
                        onRetryConnection()
                    }
                    .controlSize(.small)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            if let lastError = viewModel.lastError {
                Text(lastError)
                    .foregroundColor(.red)
                    .font(.caption)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            ForEach(torrents) { torrent in
                TorrentRowView(
                    torrent: torrent,
                    globalSeedRatioLimit: viewModel.sessionSeedRatioLimit,
                    globalSeedRatioLimited: viewModel.sessionSeedRatioLimited,
                    compact: compact,
                    onToggle: { onToggle(torrent) },
                    onRequestRemove: { onRequestRemove(torrent, false) },
                    onRequestRemoveWithData: { onRequestRemove(torrent, true) },
                    onVerify: { onVerify(torrent) },
                    onReannounce: { onReannounce(torrent) },
                    onQueueMoveTop: { onQueueMoveTop(torrent) },
                    onQueueMoveUp: { onQueueMoveUp(torrent) },
                    onQueueMoveDown: { onQueueMoveDown(torrent) },
                    onQueueMoveBottom: { onQueueMoveBottom(torrent) },
                    onSetPriorityLow: { onSetPriorityLow(torrent) },
                    onSetPriorityNormal: { onSetPriorityNormal(torrent) },
                    onSetPriorityHigh: { onSetPriorityHigh(torrent) },
                    onSetLocation: { onSetLocation(torrent) },
                    onFileSelection: { onFileSelection(torrent) },
                    onTrackers: { onTrackers(torrent) },
                    onStats: { onStats(torrent) },
                    onPeers: { onPeers(torrent) },
                    onSeedingLimits: { onSeedingLimits(torrent) },
                    onRename: { onRename(torrent) },
                    onLabels: { onLabels(torrent) },
                    onErrorDetails: { onErrorDetails(torrent) }
                )
                .listRowInsets(EdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8))
                .id("\(service.id.uuidString)-\(torrent.id)")
            }
        } header: {
            HStack {
                Text(service.name)
                    .font(.headline)
                Spacer()
                Button {
                    onToggleAltSpeed()
                } label: {
                    Image(systemName: viewModel.altSpeedEnabled ? "tortoise.fill" : "tortoise")
                        .foregroundStyle(viewModel.altSpeedEnabled ? Color.green : Color.primary)
                }
                .buttonStyle(.borderless)
                .help("Temporary Speed Limit")
                Button {
                    onAddTorrent()
                } label: {
                    Image(systemName: "plus")
                }
                .buttonStyle(.borderless)
                .help("Add Torrent")
            }
            .padding(.trailing, 6)
        }
    }

    private func filteredTorrents(_ torrents: [TorrentInfo]) -> [TorrentInfo] {
        var result = torrents

        if !filterState.searchText.isEmpty {
            result = result.filter { $0.name.localizedCaseInsensitiveContains(filterState.searchText) }
        }

        result = result.filter { filterState.statusFilter.matches($0) }

        switch filterState.sortOrder {
        case .name:
            return result.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        case .progress:
            return result.sorted { $0.percentDone > $1.percentDone }
        case .eta:
            return result.sorted { $0.eta < $1.eta }
        case .activity:
            return result.sorted { $0.isActive && !$1.isActive }
        }
    }
}
