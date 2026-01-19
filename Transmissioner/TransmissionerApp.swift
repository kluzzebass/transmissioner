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

        Window("Bandwidth Limits", id: "bandwidth") {
            BandwidthLimitsView()
                .environmentObject(serviceStore)
                .environmentObject(appState)
        }

        Window("Set Location", id: "set-location") {
            MoveLocationView()
                .environmentObject(serviceStore)
                .environmentObject(appState)
        }

        Window("File Selection", id: "file-selection") {
            FileSelectionView()
                .environmentObject(serviceStore)
                .environmentObject(appState)
        }

        Window("Session Info", id: "session-info") {
            SessionInfoView()
                .environmentObject(serviceStore)
                .environmentObject(appState)
        }

        Window("Free Space", id: "free-space") {
            FreeSpaceView()
                .environmentObject(serviceStore)
                .environmentObject(appState)
        }

        Window("Trackers", id: "trackers") {
            TrackersView()
                .environmentObject(serviceStore)
                .environmentObject(appState)
        }

        Window("Torrent Stats", id: "torrent-stats") {
            TorrentStatsView()
                .environmentObject(serviceStore)
                .environmentObject(appState)
        }

        Window("Peers", id: "peers") {
            PeersView()
                .environmentObject(serviceStore)
                .environmentObject(appState)
        }

        Window("Seeding Limits", id: "seeding-limits") {
            SeedingLimitsView()
                .environmentObject(serviceStore)
                .environmentObject(appState)
        }

        Window("Rename Torrent", id: "rename-torrent") {
            RenameTorrentView()
                .environmentObject(serviceStore)
                .environmentObject(appState)
        }

        Window("Labels", id: "labels") {
            LabelsView()
                .environmentObject(serviceStore)
                .environmentObject(appState)
        }

        Window("Error Details", id: "error-details") {
            TorrentErrorDetailsView()
                .environmentObject(serviceStore)
                .environmentObject(appState)
        }

        Window("Session Settings", id: "session-settings") {
            SessionSettingsView()
                .environmentObject(serviceStore)
                .environmentObject(appState)
        }

        Window("Blocklist", id: "blocklist") {
            BlocklistView()
                .environmentObject(serviceStore)
                .environmentObject(appState)
        }

        Window("Port Settings", id: "port-settings") {
            PortSettingsView()
                .environmentObject(serviceStore)
                .environmentObject(appState)
        }

        Window("Connection Diagnostics", id: "connection-diagnostics") {
            ConnectionDiagnosticsView()
                .environmentObject(serviceStore)
                .environmentObject(appState)
        }

    }
}
