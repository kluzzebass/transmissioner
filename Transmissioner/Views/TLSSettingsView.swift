import SwiftUI

struct TLSSettingsView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            GroupBox("HTTPS guidance") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Use https:// for encrypted connections.")
                    Text("If your server uses a self‑signed certificate, enable the insecure TLS toggle below.")
                        .foregroundColor(.secondary)
                    Text("For production, install a valid certificate to avoid insecure connections.")
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            Spacer()

            HStack {
                Spacer()
                Button("Close") { dismiss() }
            }
        }
        .padding(20)
        .frame(maxHeight: .infinity, alignment: .topLeading)
        .frame(width: 440, height: 300)
    }
}
