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

    }
}
