import SwiftUI

@main
struct TransmissionerApp: App {
    @StateObject private var serviceStore = ServiceStore()
    @StateObject private var appState = AppState()
    @StateObject private var preferences = PreferencesStore()
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        MenuBarExtra("Transmissioner", image: "MenuBarIcon") {
            MenuBarPopoverView()
                .environmentObject(serviceStore)
                .environmentObject(appState)
                .environmentObject(preferences)
        }
        .menuBarExtraStyle(.window)

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

    }
}
