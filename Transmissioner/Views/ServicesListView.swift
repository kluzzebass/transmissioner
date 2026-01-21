import SwiftUI

struct ServicesListView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var preferences: PreferencesStore
    @Environment(\.openWindow) private var openWindow

    let services: [ServiceConfig]
    let allowInsecureTLS: Bool
    @ObservedObject var viewModelStore: ServiceViewModelStore
    @ObservedObject var filterState: FilterState
    @Binding var addTorrentService: ServiceConfig?
    @Binding var pendingRemoval: PendingRemoval?

    var body: some View {
        List {
            ForEach(services) { service in
                serviceSection(for: service)
            }
        }
        .listStyle(.inset)
        .transaction { transaction in
            transaction.disablesAnimations = true
        }
    }

    private func serviceSection(for service: ServiceConfig) -> some View {
        let viewModel = viewModelStore.viewModel(for: service, allowInsecureTLS: allowInsecureTLS)
        return ServiceSectionView(
            service: service,
            viewModel: viewModel,
            filterState: filterState,
            compact: preferences.compactView,
            onAddTorrent: {
                appState.selectedServiceID = service.id
                addTorrentService = service
            },
            onToggleAltSpeed: {
                Task { await viewModel.setAltSpeed(enabled: !viewModel.altSpeedEnabled) }
            },
            onToggle: { torrent in
                Task { await toggle(torrent, using: viewModel) }
            },
            onRequestRemove: { torrent, deleteData in
                pendingRemoval = PendingRemoval(service: service, torrent: torrent, deleteData: deleteData)
            },
            onVerify: { torrent in
                Task { await viewModel.verify(ids: [torrent.id]) }
            },
            onReannounce: { torrent in
                Task { await viewModel.reannounce(ids: [torrent.id]) }
            },
            onQueueMoveTop: { torrent in
                Task { await viewModel.moveQueueTop(ids: [torrent.id]) }
            },
            onQueueMoveUp: { torrent in
                Task { await viewModel.moveQueueUp(ids: [torrent.id]) }
            },
            onQueueMoveDown: { torrent in
                Task { await viewModel.moveQueueDown(ids: [torrent.id]) }
            },
            onQueueMoveBottom: { torrent in
                Task { await viewModel.moveQueueBottom(ids: [torrent.id]) }
            },
            onSetPriorityLow: { torrent in
                Task { await viewModel.setBandwidthPriority(ids: [torrent.id], priority: -1) }
            },
            onSetPriorityNormal: { torrent in
                Task { await viewModel.setBandwidthPriority(ids: [torrent.id], priority: 0) }
            },
            onSetPriorityHigh: { torrent in
                Task { await viewModel.setBandwidthPriority(ids: [torrent.id], priority: 1) }
            },
            onSetLocation: { torrent in
                appState.selectedServiceID = service.id
                appState.moveLocationTorrentIDs = [torrent.id]
                NSApp.activate(ignoringOtherApps: true)
                openWindow(id: "set-location")
            },
            onFileSelection: { torrent in
                appState.selectedServiceID = service.id
                appState.fileSelectionTorrentID = torrent.id
                NSApp.activate(ignoringOtherApps: true)
                openWindow(id: "file-selection")
            },
            onTrackers: { torrent in
                appState.selectedServiceID = service.id
                appState.trackersTorrentID = torrent.id
                NSApp.activate(ignoringOtherApps: true)
                openWindow(id: "trackers")
            },
            onStats: { torrent in
                appState.selectedServiceID = service.id
                appState.statsTorrentID = torrent.id
                NSApp.activate(ignoringOtherApps: true)
                openWindow(id: "torrent-stats")
            },
            onPeers: { torrent in
                appState.selectedServiceID = service.id
                appState.peersTorrentID = torrent.id
                NSApp.activate(ignoringOtherApps: true)
                openWindow(id: "peers")
            },
            onSeedingLimits: { torrent in
                appState.selectedServiceID = service.id
                appState.seedingLimitsTorrentID = torrent.id
                NSApp.activate(ignoringOtherApps: true)
                openWindow(id: "seeding-limits")
            },
            onRename: { torrent in
                appState.selectedServiceID = service.id
                appState.renameTorrentID = torrent.id
                NSApp.activate(ignoringOtherApps: true)
                openWindow(id: "rename-torrent")
            },
            onLabels: { torrent in
                appState.selectedServiceID = service.id
                appState.labelsTorrentID = torrent.id
                NSApp.activate(ignoringOtherApps: true)
                openWindow(id: "labels")
            },
            onErrorDetails: { torrent in
                appState.selectedServiceID = service.id
                appState.errorDetailsTorrentID = torrent.id
                NSApp.activate(ignoringOtherApps: true)
                openWindow(id: "error-details")
            },
            onRetryConnection: {
                Task { await viewModel.refresh() }
            }
        )
    }

    private func toggle(_ torrent: TorrentInfo, using viewModel: TorrentListViewModel) async {
        if torrent.isActive {
            await viewModel.stop(ids: [torrent.id])
        } else {
            await viewModel.start(ids: [torrent.id])
        }
    }
}
