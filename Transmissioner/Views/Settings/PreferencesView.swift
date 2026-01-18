import SwiftUI

struct PreferencesView: View {
    @EnvironmentObject private var preferences: PreferencesStore

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Preferences")
                .font(.title2.weight(.semibold))

            Toggle("Auto refresh torrents", isOn: $preferences.autoRefresh)

            HStack {
                Text("Refresh interval")
                Stepper(value: $preferences.autoRefreshInterval, in: 5...60, step: 5) {
                    Text("\(Int(preferences.autoRefreshInterval)) seconds")
                        .frame(minWidth: 120, alignment: .leading)
                }
                .disabled(!preferences.autoRefresh)
            }

            Spacer()
        }
        .padding(16)
    }
}
