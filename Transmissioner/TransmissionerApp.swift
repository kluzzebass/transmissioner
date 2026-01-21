import AppKit
import SwiftUI

@main
struct TransmissionerApp: App {
    @StateObject private var serviceStore = ServiceStore()
    @StateObject private var appState = AppState()
    @StateObject private var preferences = PreferencesStore()
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @Environment(\.openWindow) private var openWindow

    var body: some Scene {
        MenuBarExtra("Transmissioner", image: "MenuBarIcon") {
            MenuBarPopoverView()
                .environmentObject(serviceStore)
                .environmentObject(appState)
                .environmentObject(preferences)
        }
        .menuBarExtraStyle(.window)
        .commands {
            CommandMenu("Transmissioner") {
                Button("Open Settings") {
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
        }

        Window("Set Location", id: "set-location") {
            MoveLocationView()
                .environmentObject(serviceStore)
                .environmentObject(appState)
                .environmentObject(preferences)
        }

        Window("File Selection", id: "file-selection") {
            FileSelectionView()
                .environmentObject(serviceStore)
                .environmentObject(appState)
                .environmentObject(preferences)
        }

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

        Window("Torrent Stats", id: "torrent-stats") {
            TorrentStatsView()
                .environmentObject(serviceStore)
                .environmentObject(appState)
                .environmentObject(preferences)
        }

        Window("Peers", id: "peers") {
            PeersView()
                .environmentObject(serviceStore)
                .environmentObject(appState)
                .environmentObject(preferences)
        }

        Window("Seeding Limits", id: "seeding-limits") {
            SeedingLimitsView()
                .environmentObject(serviceStore)
                .environmentObject(appState)
                .environmentObject(preferences)
        }

        Window("Rename Torrent", id: "rename-torrent") {
            RenameTorrentView()
                .environmentObject(serviceStore)
                .environmentObject(appState)
                .environmentObject(preferences)
        }

        Window("Labels", id: "labels") {
            LabelsView()
                .environmentObject(serviceStore)
                .environmentObject(appState)
                .environmentObject(preferences)
        }

        Window("Error Details", id: "error-details") {
            TorrentErrorDetailsView()
                .environmentObject(serviceStore)
                .environmentObject(appState)
                .environmentObject(preferences)
        }

        Window("Server Settings", id: "server-settings") {
            TransmissionSettingsView()
                .environmentObject(serviceStore)
                .environmentObject(appState)
                .environmentObject(preferences)
        }
        .defaultSize(width: 630, height: 320)
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
