import SwiftUI

struct SettingsView: View {
    var body: some View {
        TabView {
            ServicesSettingsView()
                .tabItem { Label("Services", systemImage: "antenna.radiowaves.left.and.right") }

            PreferencesView()
                .tabItem { Label("Preferences", systemImage: "gearshape") }
        }
        .frame(width: 560, height: 380)
    }
}
