import SwiftUI

struct SessionInfoView: View {
    @EnvironmentObject private var serviceStore: ServiceStore
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var version: String = "—"
    @State private var downloadDir: String = "—"

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Session Info")
                    .font(.title2.weight(.semibold))
                Spacer()
                if isLoading {
                    ProgressView()
                        .controlSize(.small)
                }
            }

            if let errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundColor(.red)
            }

            Form {
                LabeledContent("Version") {
                    Text(version)
                        .monospacedDigit()
                }
                LabeledContent("Default download dir") {
                    Text(downloadDir)
                        .lineLimit(2)
                        .truncationMode(.middle)
                }
            }

            HStack {
                Spacer()
                Button("Close") { dismiss() }
            }
        }
        .padding(20)
        .frame(minWidth: 420)
        .onAppear(perform: load)
        .onChange(of: appState.selectedServiceID) { _, _ in load() }
    }

    private func load() {
        guard let service = selectedService else {
            errorMessage = "Select a service to view session info."
            return
        }

        errorMessage = nil
        isLoading = true

        Task {
            defer { isLoading = false }
            do {
                let client = TransmissionRPCClient(config: service)
                let response: SessionGetResponseArguments = try await client.request(
                    method: "session-get",
                    arguments: SessionGetArguments()
                )
                version = response.version ?? "—"
                downloadDir = response.downloadDir ?? "—"
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    private var selectedService: ServiceConfig? {
        let configured = serviceStore.service(id: appState.selectedServiceID)
        if let configured {
            return configured
        }
        return serviceStore.services.first
    }
}
