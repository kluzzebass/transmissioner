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
                Picker("", selection: $autoRefreshInterval) {
                    ForEach([1, 2, 3, 4, 5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55, 60], id: \.self) { value in
                        Text("\(value) seconds").tag(Double(value))
                    }
                }
                .disabled(!autoRefresh)
                .frame(minWidth: 120)
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
