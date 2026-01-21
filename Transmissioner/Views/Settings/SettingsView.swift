import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var serviceStore: ServiceStore
    @EnvironmentObject private var preferences: PreferencesStore
    @Environment(\.dismiss) private var dismiss

    @State private var draftAutoRefresh = true
    @State private var draftAutoRefreshInterval = 20.0
    @State private var draftAllowInsecureTLS = false
    @State private var draftServices: [ServiceConfig] = []

    var body: some View {
        VStack(spacing: 12) {
            TabView {
                PreferencesView(
                    autoRefresh: $draftAutoRefresh,
                    autoRefreshInterval: $draftAutoRefreshInterval,
                    allowInsecureTLS: $draftAllowInsecureTLS
                )
                    .tabItem { Label("Preferences", systemImage: "gearshape") }

                ServicesSettingsView(services: $draftServices)
                    .tabItem { Label("Services", systemImage: "antenna.radiowaves.left.and.right") }
            }

            HStack {
                Spacer()
                Button("Cancel") {
                    resetDrafts()
                    dismiss()
                }
                Button("OK") {
                    applyDrafts()
                    dismiss()
                }
                    .buttonStyle(.borderedProminent)
            }
        }
        .padding(.bottom, 12)
        .frame(minWidth: 560, minHeight: 380)
        .onAppear(perform: resetDrafts)
    }

    private func resetDrafts() {
        draftAutoRefresh = preferences.autoRefresh
        draftAutoRefreshInterval = preferences.autoRefreshInterval
        draftAllowInsecureTLS = preferences.allowInsecureTLS
        draftServices = serviceStore.services
    }

    private func applyDrafts() {
        preferences.autoRefresh = draftAutoRefresh
        preferences.autoRefreshInterval = draftAutoRefreshInterval
        preferences.allowInsecureTLS = draftAllowInsecureTLS
        serviceStore.replaceAll(draftServices)
    }
}
