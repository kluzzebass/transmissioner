import AppKit
import SwiftUI

struct TransmissionInfoView: View {
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Information")
                .font(.title2.weight(.semibold))

            GroupBox("Session") {
                VStack(alignment: .leading, spacing: 8) {
                    infoButton("Session Info", windowID: "session-info")
                    infoButton("Free Space", windowID: "free-space")
                }
            }

            GroupBox("Diagnostics") {
                VStack(alignment: .leading, spacing: 8) {
                    infoButton("Connection Diagnostics", windowID: "connection-diagnostics")
                }
            }

            Spacer()
        }
        .padding(16)
    }

    private func infoButton(_ title: String, windowID: String) -> some View {
        Button(title) {
            NSApp.activate(ignoringOtherApps: true)
            openWindow(id: windowID)
        }
        .buttonStyle(.bordered)
    }
}
