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
    @State private var popoverSize = MenuBarPopoverView.loadPopoverSize()

    var body: some View {
        VStack(spacing: 12) {
            header

            if selectedService != nil {
                TorrentListView(
                    viewModel: viewModel,
                    compact: true,
                    onUserInteraction: {}
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
        .frame(minWidth: 360, minHeight: 260)
        .background(WindowAccessor(
            minSize: CGSize(width: 360, height: 260),
            initialSize: popoverSize,
            onResize: { newSize in
                let clamped = MenuBarPopoverView.clampedSize(newSize)
                popoverSize = clamped
                MenuBarPopoverView.savePopoverSize(clamped)
            }
        ))
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
            guard !isMenuTracking else { return }
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
                Button("Reset Window Size") {
                    MenuBarPopoverView.resetPopoverSize()
                }
            } label: {
                Label(selectedService?.name ?? "No Service", systemImage: "antenna.radiowaves.left.and.right")
            }

            Spacer()

            Button {
                Task { await viewModel.refresh() }
            } label: {
                Image(systemName: "arrow.clockwise")
            }
            .help("Refresh")

            Button {
                showingAddTorrent = true
            } label: {
                Image(systemName: "plus")
            }
            .help("Add Torrent")
            .disabled(selectedService == nil)

            Button {
                NSApplication.shared.terminate(nil)
            } label: {
                Image(systemName: "power")
            }
            .help("Quit")
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
}

private extension MenuBarPopoverView {
    struct StoredSize: Codable {
        let width: Double
        let height: Double
    }

    static let popoverSizeKey = "menuBarPopoverSize"

    static func loadPopoverSize() -> CGSize {
        let defaults = UserDefaults.standard
        guard let data = defaults.data(forKey: popoverSizeKey),
              let stored = try? JSONDecoder().decode(StoredSize.self, from: data) else {
            return clampedSize(CGSize(width: 500, height: 520))
        }
        return clampedSize(CGSize(width: stored.width, height: stored.height))
    }

    static func savePopoverSize(_ size: CGSize) {
        let clamped = clampedSize(size)
        let stored = StoredSize(width: clamped.width, height: clamped.height)
        if let data = try? JSONEncoder().encode(stored) {
            UserDefaults.standard.set(data, forKey: popoverSizeKey)
        }
    }

    static func resetPopoverSize() {
        UserDefaults.standard.removeObject(forKey: popoverSizeKey)
    }

    static func clampedSize(_ size: CGSize) -> CGSize {
        let minWidth: CGFloat = 360
        let minHeight: CGFloat = 260
        let screenSize = NSScreen.main?.visibleFrame.size ?? CGSize(width: 1200, height: 900)
        let maxWidth = max(minWidth, screenSize.width * 0.9)
        let maxHeight = max(minHeight, screenSize.height * 0.9)
        return CGSize(
            width: min(max(size.width, minWidth), maxWidth),
            height: min(max(size.height, minHeight), maxHeight)
        )
    }
}
