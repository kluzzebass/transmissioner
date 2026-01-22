import SwiftUI

struct PreferencesView: View {
    @Binding var autoRefresh: Bool
    @Binding var autoRefreshInterval: Double
    @Binding var allowInsecureTLS: Bool
    @Binding var runAtLogin: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Toggle("Auto refresh torrents", isOn: $autoRefresh)

            HStack {
                Text("Refresh interval")
                Stepper(value: $autoRefreshInterval, in: 5...60, step: 5) {
                    Text("\(Int(autoRefreshInterval)) seconds")
                        .frame(minWidth: 120, alignment: .leading)
                }
                .disabled(!autoRefresh)
            }

            Divider()

            Toggle("Allow insecure TLS (self‑signed/legacy)", isOn: $allowInsecureTLS)
                .help("Relaxes App Transport Security checks for Transmission connections.")

            Toggle("Run at startup", isOn: $runAtLogin)

            Spacer()
        }
        .padding(16)
    }
}
