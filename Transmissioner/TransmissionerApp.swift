import AppKit
import SwiftUI
import OSLog

@main
struct TransmissionerApp: App {
    @StateObject private var serviceStore = ServiceStore()
    @StateObject private var appState = AppState()
    @StateObject private var preferences = PreferencesStore()
    @StateObject private var viewModelStore = ServiceViewModelStore()
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @Environment(\.openWindow) private var openWindow
    private let logger = Logger(subsystem: "org.radical.Transmissioner", category: "TransmissionerApp")

    var body: some Scene {
        MenuBarExtra {
            MenuBarPopoverView()
                .environmentObject(serviceStore)
                .environmentObject(appState)
                .environmentObject(preferences)
                .environmentObject(viewModelStore)
                .onAppear {
                    // Give AppDelegate access to AppState
                    appDelegate.appState = appState
                }
                .onOpenURL { url in
                    logger.info("🔗 SwiftUI onOpenURL received: \(url.absoluteString)")
                    if url.scheme == "magnet" {
                        let magnetLink = url.absoluteString
                        logger.info("🔗 Storing magnet link in AppState via onOpenURL: \(magnetLink.prefix(50))...")
                        appState.pendingMagnetLink = magnetLink
                        // Don't activate the app - let it process silently
                        // Activating might cause SwiftUI to auto-open windows
                    }
                }
        } label: {
            MenuBarIconView(viewModelStore: viewModelStore)
        }
        .menuBarExtraStyle(.window)
        .commands {
            CommandMenu("Transmissioner") {
                Button("Open Settings") {
                    logger.info("🔧 Command menu: Open Settings clicked")
                    NSApp.activate(ignoringOtherApps: true)
                    openWindow(id: "settings")
                }
                .keyboardShortcut(",", modifiers: .command)

                Button("Add Torrent") {
                    NotificationCenter.default.post(name: .showAddTorrent, object: nil)
                }
                .keyboardShortcut("n", modifiers: .command)

                Button("Refresh Torrents") {
                    NotificationCenter.default.post(name: .refreshTorrents, object: nil)
                }
                .keyboardShortcut("r", modifiers: .command)

                Button("Toggle Compact View") {
                    NotificationCenter.default.post(name: .toggleCompactView, object: nil)
                }
                .keyboardShortcut("c", modifiers: [.command, .shift])
            }
        }

        Window("Settings", id: "settings") {
            SettingsView()
                .environmentObject(serviceStore)
                .environmentObject(appState)
                .environmentObject(preferences)
                .onAppear {
                    logger.info("🔧 Settings window appeared - stack: \(Thread.callStackSymbols.prefix(5).joined(separator: " -> "))")
                }
        }
        .defaultSize(width: 520, height: 340)
        .windowResizability(.contentSize)
        .defaultLaunchBehavior(.suppressed)
        .restorationBehavior(.disabled)

        Window("Set Location", id: "set-location") {
            MoveLocationView()
                .environmentObject(serviceStore)
                .environmentObject(appState)
                .environmentObject(preferences)
        }
        .defaultSize(width: 480, height: 200)
        .windowResizability(.contentSize)

        Window("File Selection", id: "file-selection") {
            FileSelectionView()
                .environmentObject(serviceStore)
                .environmentObject(appState)
                .environmentObject(preferences)
        }
        .defaultSize(width: 600, height: 520)
        .windowResizability(.contentSize)

        Window("Session Info", id: "session-info") {
            SessionInfoView()
                .environmentObject(serviceStore)
                .environmentObject(appState)
                .environmentObject(preferences)
        }
        .defaultSize(width: 440, height: 300)
        .windowResizability(.contentSize)

        Window("Free Space", id: "free-space") {
            FreeSpaceView()
                .environmentObject(serviceStore)
                .environmentObject(appState)
                .environmentObject(preferences)
        }
        .defaultSize(width: 440, height: 300)
        .windowResizability(.contentSize)

        Window("Trackers", id: "trackers") {
            TrackersView()
                .environmentObject(serviceStore)
                .environmentObject(appState)
                .environmentObject(preferences)
        }
        .defaultSize(width: 600, height: 520)
        .windowResizability(.contentSize)

        Window("Torrent Stats", id: "torrent-stats") {
            TorrentStatsView()
                .environmentObject(serviceStore)
                .environmentObject(appState)
                .environmentObject(preferences)
        }
        .defaultSize(width: 460, height: 500)
        .windowResizability(.contentSize)

        Window("Peers", id: "peers") {
            PeersView()
                .environmentObject(serviceStore)
                .environmentObject(appState)
                .environmentObject(preferences)
        }
        .defaultSize(width: 640, height: 520)
        .windowResizability(.contentSize)

        Window("Seeding Limits", id: "seeding-limits") {
            SeedingLimitsView()
                .environmentObject(serviceStore)
                .environmentObject(appState)
                .environmentObject(preferences)
        }
        .windowResizability(.contentSize)

        Window("Labels", id: "labels") {
            LabelsView()
                .environmentObject(serviceStore)
                .environmentObject(appState)
                .environmentObject(preferences)
        }
        .defaultSize(width: 460, height: 420)
        .windowResizability(.contentSize)

        Window("Error Details", id: "error-details") {
            TorrentErrorDetailsView()
                .environmentObject(serviceStore)
                .environmentObject(appState)
                .environmentObject(preferences)
        }
        .defaultSize(width: 480, height: 400)
        .windowResizability(.contentSize)

        Window("Server Settings", id: "server-settings") {
            TransmissionSettingsView()
                .environmentObject(serviceStore)
                .environmentObject(appState)
                .environmentObject(preferences)
        }
        .defaultSize(width: 360, height: 320)
        .windowResizability(.contentSize)

        Window("Connection Diagnostics", id: "connection-diagnostics") {
            ConnectionDiagnosticsView()
                .environmentObject(serviceStore)
                .environmentObject(appState)
                .environmentObject(preferences)
        }
        .defaultSize(width: 440, height: 300)
        .windowResizability(.contentSize)

    }
}
