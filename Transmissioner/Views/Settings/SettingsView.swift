import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var serviceStore: ServiceStore
    @EnvironmentObject private var preferences: PreferencesStore
    @Environment(\.dismiss) private var dismiss

    @State private var draftAutoRefresh = true
    @State private var draftAutoRefreshInterval = 20.0
    @State private var draftAllowInsecureTLS = false
    @State private var draftRunAtLogin = false
    @State private var draftServices: [ServiceConfig] = []
    @State private var applyErrorMessage: String?

    var body: some View {
        VStack(spacing: 12) {
            TabView {
                PreferencesView(
                    autoRefresh: $draftAutoRefresh,
                    autoRefreshInterval: $draftAutoRefreshInterval,
                    allowInsecureTLS: $draftAllowInsecureTLS,
                    runAtLogin: $draftRunAtLogin
                )
                    .tabItem { Label("Preferences", systemImage: "gearshape") }

                ServicesSettingsView(services: $draftServices)
                    .tabItem { Label("Services", systemImage: "antenna.radiowaves.left.and.right") }
            }

            if let applyErrorMessage {
                Text(applyErrorMessage)
                    .font(.caption)
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            Divider()

            Text("Copyright © 2026 Jan Fredrik Leversund. All rights reserved.")
                .font(.caption2)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)

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
            .padding(.horizontal, 16)
        }
        .padding(.bottom, 12)
        .frame(width: 520, height: 340)
        .onAppear(perform: resetDrafts)
    }

    private func resetDrafts() {
        draftAutoRefresh = preferences.autoRefresh
        draftAutoRefreshInterval = preferences.autoRefreshInterval
        draftAllowInsecureTLS = preferences.allowInsecureTLS
        draftRunAtLogin = preferences.runAtLoginEnabled()
        draftServices = serviceStore.services
        applyErrorMessage = nil
    }

    private func applyDrafts() {
        preferences.autoRefresh = draftAutoRefresh
        preferences.autoRefreshInterval = draftAutoRefreshInterval
        preferences.allowInsecureTLS = draftAllowInsecureTLS
        serviceStore.replaceAll(draftServices)
        applyErrorMessage = nil
        do {
            try preferences.setRunAtLogin(enabled: draftRunAtLogin)
        } catch {
            applyErrorMessage = error.localizedDescription
        }
    }
}
