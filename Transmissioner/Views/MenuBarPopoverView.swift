import AppKit
import Combine
import SwiftUI

struct MenuBarPopoverView: View {
    @EnvironmentObject private var serviceStore: ServiceStore
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var preferences: PreferencesStore
    @Environment(\.openWindow) private var openWindow
    @StateObject private var viewModel = TorrentListViewModel()
    @State private var showingAddTorrent = false
    @State private var suppressRefreshUntil = Date.distantPast
    @State private var isMenuTracking = false
    @StateObject private var filterState = FilterState()

    var body: some View {
        VStack(spacing: 12) {
            header

            if selectedService != nil {
                FilterBarView(filterState: filterState)

                TorrentListView(
                    viewModel: viewModel,
                    torrents: filteredTorrents,
                    compact: true,
                    onSetLocation: { torrent in
                        appState.moveLocationTorrentIDs = [torrent.id]
                        NSApp.activate(ignoringOtherApps: true)
                        openWindow(id: "set-location")
                    }
                )

                HStack(spacing: 8) {
                        Button {
                        Task { await viewModel.start() }
                        } label: {
                            Image(systemName: "play.fill")
                        }
                        .help("Start All")

                        Button {
                        Task { await viewModel.stop() }
                        } label: {
                            Image(systemName: "pause.fill")
                        }
                        .help("Stop All")

            Button {
                Task { await viewModel.setAltSpeed(enabled: !viewModel.altSpeedEnabled) }
            } label: {
                Image(systemName: viewModel.altSpeedEnabled ? "tortoise.fill" : "tortoise")
                    .foregroundStyle(viewModel.altSpeedEnabled ? Color.green : Color.primary)
            }
            .help("Temporary Speed Limit")

            Button {
                NSApp.activate(ignoringOtherApps: true)
                openWindow(id: "bandwidth")
            } label: {
                Image(systemName: "speedometer")
            }
            .help("Bandwidth Limits")
            .disabled(selectedService == nil)

                    Spacer()
                        Button(action: openSettings) {
                            Image(systemName: "gearshape")
                        }
                        .help("Settings")
                }
                .buttonStyle(.bordered)
            } else {
                emptyState
            }
        }
        .padding(12)
        .frame(width: 600, height: 800)
        .overlay {
            if showingAddTorrent {
                ZStack {
                    Color.black.opacity(0.25)
                        .ignoresSafeArea()
                        .onTapGesture {
                            showingAddTorrent = false
                        }

                    AddTorrentView(
                        onAdd: { link, dir in
                            showingAddTorrent = false
                            Task { await viewModel.addTorrent(magnetLink: link, downloadDir: dir) }
                        },
                        onCancel: { showingAddTorrent = false }
                    )
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
                    .shadow(radius: 10)
                }
            }
        }
        .onAppear(perform: configureViewModel)
        .onChange(of: appState.selectedServiceID) { _, _ in configureViewModel() }
        .onReceive(refreshTimer) { _ in
            guard preferences.autoRefresh, selectedService != nil else { return }
            guard Date() >= suppressRefreshUntil else { return }
            Task { await viewModel.refresh() }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSMenu.didBeginTrackingNotification)) { _ in
            isMenuTracking = true
        }
        .onReceive(NotificationCenter.default.publisher(for: NSMenu.didEndTrackingNotification)) { _ in
            isMenuTracking = false
        }
    }

    private var header: some View {
        HStack(spacing: 8) {
            Menu {
                ForEach(serviceStore.services) { service in
                    Button(service.name) {
                        appState.selectedServiceID = service.id
                    }
                }
                if !serviceStore.services.isEmpty {
                    Divider()
                }
                Button("Manage Services", action: openSettings)
            } label: {
                Label(selectedService?.name ?? "No Service", systemImage: "antenna.radiowaves.left.and.right")
            }

            Spacer()

            headerIconButton(systemName: "arrow.clockwise", help: "Refresh") {
                Task { await viewModel.refresh() }
            }

            headerIconButton(systemName: "plus", help: "Add Torrent") {
                showingAddTorrent = true
            }
            .disabled(selectedService == nil)

            headerIconButton(systemName: "power", help: "Quit") {
                NSApplication.shared.terminate(nil)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Text("No Transmission services configured.")
                .font(.headline)
            Text("Add your first service in Settings.")
                .font(.subheadline)
                .foregroundColor(.secondary)
            Button("Open Settings", action: openSettings)
        }
        .frame(maxWidth: .infinity, minHeight: 200)
    }

    private var selectedService: ServiceConfig? {
        let configured = serviceStore.service(id: appState.selectedServiceID)
        if let configured {
            return configured
        }
        return serviceStore.services.first
    }

    private var refreshTimer: Publishers.Autoconnect<Timer.TimerPublisher> {
        Timer.publish(every: max(5, preferences.autoRefreshInterval), on: .main, in: .common)
            .autoconnect()
    }

    private struct FilterBarView: View, Equatable {
        @ObservedObject var filterState: FilterState

        static func == (lhs: FilterBarView, rhs: FilterBarView) -> Bool {
            lhs.filterState.searchText == rhs.filterState.searchText
                && lhs.filterState.statusFilter == rhs.filterState.statusFilter
                && lhs.filterState.sortOrder == rhs.filterState.sortOrder
        }

        var body: some View {
            HStack(spacing: 8) {
                TextField("Filter torrents", text: $filterState.searchText)
                    .textFieldStyle(.roundedBorder)

                Menu {
                    Picker("Status", selection: $filterState.statusFilter) {
                        ForEach(StatusFilter.allCases) { filter in
                            Text(filter.label).tag(filter)
                        }
                    }
                } label: {
                    Label(filterState.statusFilter.label, systemImage: "line.3.horizontal.decrease.circle")
                }

                Menu {
                    Picker("Sort", selection: $filterState.sortOrder) {
                        ForEach(SortOrder.allCases) { order in
                            Text(order.label).tag(order)
                        }
                    }
                } label: {
                    Label(filterState.sortOrder.label, systemImage: "arrow.up.arrow.down")
                }
            }
        }
    }

    private var filteredTorrents: [TorrentInfo] {
        var result = viewModel.torrents

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

    private func configureViewModel() {
        if appState.selectedServiceID == nil, let first = serviceStore.services.first {
            appState.selectedServiceID = first.id
        }
        viewModel.configure(with: selectedService)
    }

    private func openSettings() {
        NSApp.activate(ignoringOtherApps: true)
        openWindow(id: "settings")
    }

    private func headerIconButton(systemName: String, help: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .frame(width: 16, height: 16)
        }
        .buttonStyle(.bordered)
        .controlSize(.small)
        .frame(width: 28, height: 28)
        .contentShape(Rectangle())
        .help(help)
    }

    private enum StatusFilter: String, CaseIterable, Identifiable {
        case all
        case downloading
        case seeding
        case completed
        case stopped
        case error

        var id: String { rawValue }

        var label: String {
            switch self {
            case .all: return "All"
            case .downloading: return "Downloading"
            case .seeding: return "Seeding"
            case .completed: return "Completed"
            case .stopped: return "Stopped"
            case .error: return "Error"
            }
        }

        func matches(_ torrent: TorrentInfo) -> Bool {
            switch self {
            case .all:
                return true
            case .error:
                return (torrent.errorString?.isEmpty == false)
            case .downloading:
                return torrent.status == TransmissionStatus.downloading.rawValue
            case .seeding:
                return torrent.status == TransmissionStatus.seeding.rawValue
            case .completed:
                return torrent.isFinished
            case .stopped:
                return torrent.status == TransmissionStatus.stopped.rawValue
            }
        }
    }

    private enum SortOrder: String, CaseIterable, Identifiable {
        case name
        case progress
        case eta
        case activity

        var id: String { rawValue }

        var label: String {
            switch self {
            case .name: return "Name"
            case .progress: return "Progress"
            case .eta: return "ETA"
            case .activity: return "Active"
            }
        }
    }

    private final class FilterState: ObservableObject {
        @Published var searchText = ""
        @Published var statusFilter: StatusFilter = .all
        @Published var sortOrder: SortOrder = .name
    }

    
}

