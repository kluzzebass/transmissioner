import SwiftUI

struct SessionInfoView: View {
    @EnvironmentObject private var serviceStore: ServiceStore
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var preferences: PreferencesStore
    @Environment(\.dismiss) private var dismiss
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var version: String = "—"
    @State private var downloadDir: String = "—"

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if isLoading {
                HStack {
                    Spacer()
                    ProgressView()
                        .controlSize(.small)
                }
            }

            if let errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundColor(.red)
            }

            GroupBox {
                VStack(alignment: .leading, spacing: 10) {
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
                let client = TransmissionRPCClient(
                    config: service,
                    allowInsecureTLS: preferences.allowInsecureTLS
                )
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
