import AppKit
import Combine
import SwiftUI

struct MenuBarPopoverView: View {
    @EnvironmentObject private var serviceStore: ServiceStore
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var preferences: PreferencesStore
    @Environment(\.openWindow) private var openWindow
    @StateObject private var viewModelStore = ServiceViewModelStore()
    @State private var addTorrentService: ServiceConfig?
    @State private var suppressRefreshUntil = Date.distantPast
    @State private var isMenuTracking = false
    @StateObject private var filterState = FilterState()
    @State private var pendingRemoval: PendingRemoval?

    var body: AnyView {
        let padded = AnyView(
            mainContent
                .padding(.horizontal, 12)
                .padding(.top, 6)
                .padding(.bottom, 12)
        )
        let framed = AnyView(padded.frame(width: 600, height: 800, alignment: .top))
        let overlaid = AnyView(framed.overlay { overlayContent })
        let observed = AnyView(
            overlaid
                .onAppear(perform: configureServices)
                .onChange(of: appState.selectedServiceID) { _, _ in configureServices() }
                .onChange(of: preferences.allowInsecureTLS) { _, _ in
                    configureServices()
                }
                .onChange(of: serviceStore.services) { _, _ in
                    configureServices()
                }
                .onReceive(refreshTimer) { _ in
                    guard preferences.autoRefresh, !serviceStore.services.isEmpty else { return }
                    guard Date() >= suppressRefreshUntil else { return }
                    Task { await viewModelStore.refreshAll() }
                }
                .onReceive(NotificationCenter.default.publisher(for: .refreshTorrents)) { _ in
                    Task { await viewModelStore.refreshAll() }
                }
                .onReceive(NotificationCenter.default.publisher(for: .showAddTorrent)) { _ in
                    if let service = selectedService {
                        addTorrentService = service
                    }
                }
                .onReceive(NotificationCenter.default.publisher(for: .toggleCompactView)) { _ in
                    preferences.compactView.toggle()
                }
                .onReceive(NotificationCenter.default.publisher(for: NSMenu.didBeginTrackingNotification)) { _ in
                    isMenuTracking = true
                }
                .onReceive(NotificationCenter.default.publisher(for: NSMenu.didEndTrackingNotification)) { _ in
                    isMenuTracking = false
                }
        )
        return observed
    }

    private var mainContent: AnyView {
        AnyView(
            VStack(spacing: 12) {
                header
                if serviceStore.services.isEmpty {
                    emptyState
                } else {
                    servicesContent
                }
            }
        )
    }

    private var servicesContent: AnyView {
        AnyView(
            VStack(spacing: 12) {
                ServicesListView(
                    services: serviceStore.services,
                    allowInsecureTLS: preferences.allowInsecureTLS,
                    viewModelStore: viewModelStore,
                    filterState: filterState,
                    addTorrentService: $addTorrentService,
                    pendingRemoval: $pendingRemoval
                )
                controlsBar
            }
        )
    }

    private var controlsBar: AnyView {
        AnyView(
            HStack(spacing: 8) {
                Button {
                    Task { await viewModelStore.startAll() }
                } label: {
                    Image(systemName: "play.fill")
                }
                .help("Start All")

                Button {
                    Task { await viewModelStore.stopAll() }
                } label: {
                    Image(systemName: "pause.fill")
                }
                .help("Stop All")

                Button {
                    Task { await viewModelStore.setAltSpeed(enabled: !viewModelStore.allAltSpeedEnabled) }
                } label: {
                    Image(systemName: viewModelStore.anyAltSpeedEnabled ? "tortoise.fill" : "tortoise")
                        .foregroundStyle(viewModelStore.anyAltSpeedEnabled ? Color.green : Color.primary)
                }
                .help("Temporary Speed Limit")

                serverSettingsMenu

                Spacer()
                infoMenu
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        )
    }

    private var overlayContent: AnyView {
        AnyView(
            Group {
                if let pendingRemoval {
                    ZStack {
                        Color.black.opacity(0.3)
                            .background(.ultraThinMaterial)
                            .ignoresSafeArea()
                            .onTapGesture {
                                self.pendingRemoval = nil
                            }

                        VStack(spacing: 12) {
                            Text(pendingRemoval.deleteData ? "Remove & Delete Data" : "Remove Torrent")
                                .font(.headline)
                            Text(pendingRemoval.deleteData
                                 ? "This will remove “\(pendingRemoval.torrent.name)” and delete its local data."
                                 : "This will remove “\(pendingRemoval.torrent.name)” from Transmission.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)

                            HStack {
                                Button("Cancel") {
                                    self.pendingRemoval = nil
                                }
                                Spacer()
                                Button(pendingRemoval.deleteData ? "Delete Data" : "Remove") {
                                    let service = pendingRemoval.service
                                    let torrentID = pendingRemoval.torrent.id
                                    let deleteData = pendingRemoval.deleteData
                                    self.pendingRemoval = nil
                                    Task {
                                        let viewModel = viewModelStore.viewModel(for: service, allowInsecureTLS: preferences.allowInsecureTLS)
                                        await viewModel.remove(ids: [torrentID], deleteData: deleteData)
                                    }
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(pendingRemoval.deleteData ? .red : .accentColor)
                            }
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity)
                        .liquidGlassOverlay()
                        .padding(20)
                    }
                } else if let addTorrentService {
                    ZStack {
                        Color.black.opacity(0.3)
                            .background(.ultraThinMaterial)
                            .ignoresSafeArea()
                            .onTapGesture {
                                self.addTorrentService = nil
                            }

                AddTorrentView(
                    onAdd: { link, data, dir in
                                let service = addTorrentService
                                self.addTorrentService = nil
                                Task {
                                    let viewModel = viewModelStore.viewModel(for: service, allowInsecureTLS: preferences.allowInsecureTLS)
                            await viewModel.addTorrent(magnetLink: link, torrentData: data, downloadDir: dir)
                                }
                            },
                            onCancel: { self.addTorrentService = nil }
                        )
                        .liquidGlassOverlay()
                    }
                }
            }
        )
    }

    private var header: some View {
        HStack(spacing: 8) {
            FilterBarView(filterState: filterState, compactView: $preferences.compactView)
                .layoutPriority(1)

            Spacer()

            headerIconButton(systemName: "arrow.clockwise", help: "Refresh") {
                Task { await viewModelStore.refreshAll() }
            }

            headerIconButton(systemName: "antenna.radiowaves.left.and.right", help: "Manage Services") {
                openSettings(tab: "services")
            }

            headerIconButton(systemName: "gearshape", help: "Settings") {
                openSettings(tab: "preferences")
            }

            headerIconButton(systemName: "power", help: "Quit") {
                NSApplication.shared.terminate(nil)
            }
        }
        .controlSize(.small)
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Text("No Transmission services configured.")
                .font(.headline)
            Text("Add your first service in Settings.")
                .font(.subheadline)
                .foregroundColor(.secondary)
            Button("Open Settings") {
                openSettings(tab: "services")
            }
        }
        .frame(maxWidth: .infinity, minHeight: 200)
    }

    private var infoMenu: some View {
        Menu {
            Button("Session Info") {
                NSApp.activate(ignoringOtherApps: true)
                openWindow(id: "session-info")
            }
            Button("Free Space") {
                NSApp.activate(ignoringOtherApps: true)
                openWindow(id: "free-space")
            }
            Button("Connection Diagnostics") {
                NSApp.activate(ignoringOtherApps: true)
                openWindow(id: "connection-diagnostics")
            }
        } label: {
            Image(systemName: "info.circle")
        }
        .help("Info")
        .disabled(selectedService == nil)
    }

    private var serverSettingsMenu: some View {
        Menu {
            Button("Session Settings") { openServerSettings(section: "session") }
            Button("Bandwidth Limits") { openServerSettings(section: "bandwidth") }
            Button("Blocklist") { openServerSettings(section: "blocklist") }
            Button("Port Settings") { openServerSettings(section: "port") }
        } label: {
            Image(systemName: "gearshape.2")
        }
        .help("Server Settings")
        .disabled(selectedService == nil)
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
        @Binding var compactView: Bool

        static func == (lhs: FilterBarView, rhs: FilterBarView) -> Bool {
            lhs.filterState.searchText == rhs.filterState.searchText
                && lhs.filterState.statusFilter == rhs.filterState.statusFilter
                && lhs.filterState.sortOrder == rhs.filterState.sortOrder
                && lhs.compactView == rhs.compactView
        }

        var body: some View {
            HStack(spacing: 8) {
                TextField("Filter torrents", text: $filterState.searchText)
                    .textFieldStyle(.roundedBorder)
                    .controlSize(.small)

                Menu {
                    Picker("Status", selection: $filterState.statusFilter) {
                        ForEach(StatusFilter.allCases) { filter in
                            Text(filter.label).tag(filter)
                        }
                    }
                } label: {
                    Label(filterState.statusFilter.label, systemImage: "line.3.horizontal.decrease.circle")
                }
                .controlSize(.small)

                Menu {
                    Picker("Sort", selection: $filterState.sortOrder) {
                        ForEach(SortOrder.allCases) { order in
                            Text(order.label).tag(order)
                        }
                    }
                } label: {
                    Label(filterState.sortOrder.label, systemImage: "arrow.up.arrow.down")
                }
                .controlSize(.small)

                Button {
                    compactView.toggle()
                } label: {
                    Image(systemName: compactView ? "rectangle.compress.vertical" : "rectangle.expand.vertical")
                }
                .help(compactView ? "Switch to Detailed View" : "Switch to Compact View")
                .controlSize(.small)
            }
        }
    }

    private func configureServices() {
        if appState.selectedServiceID == nil, let first = serviceStore.services.first {
            appState.selectedServiceID = first.id
        }
        viewModelStore.removeMissingServices(serviceStore.services)
        for service in serviceStore.services {
            _ = viewModelStore.viewModel(for: service, allowInsecureTLS: preferences.allowInsecureTLS)
        }
    }

    private func openSettings(tab: String) {
        appState.settingsTab = tab
        NSApp.activate(ignoringOtherApps: true)
        openWindow(id: "settings")
    }

    private func openServerSettings(section: String) {
        appState.serverSettingsSection = section
        NSApp.activate(ignoringOtherApps: true)
        openWindow(id: "server-settings")
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

}

