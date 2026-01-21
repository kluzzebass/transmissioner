import SwiftUI

struct ConnectionDiagnosticsView: View {
    @EnvironmentObject private var serviceStore: ServiceStore
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var preferences: PreferencesStore
    @Environment(\.dismiss) private var dismiss
    @State private var isTesting = false
    @State private var testResult: TestResult?
    @State private var errorMessage: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if isTesting {
                HStack {
                    Spacer()
                    ProgressView()
                        .controlSize(.small)
                }
            }

            GroupBox("Service") {
                if let service = selectedService {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(service.name)
                            .font(.headline)
                        Text(service.rpcURL.absoluteString)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(service.username.isEmpty ? "Auth: none" : "Auth: username set")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    Text("No services configured. Add one in Settings.")
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }

            if let errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundColor(.red)
            }

            if let testResult {
                GroupBox("Result") {
                    VStack(alignment: .leading, spacing: 10) {
                        LabeledContent("Status") {
                            Text(testResult.success ? "Connected" : "Failed")
                                .foregroundColor(testResult.success ? .green : .red)
                        }
                        LabeledContent("Latency") {
                            Text("\(testResult.durationMs) ms")
                                .monospacedDigit()
                        }
                        LabeledContent("Version") {
                            Text(testResult.version ?? "—")
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }

            Spacer()

            HStack {
                Button("Test Connection") { Task { await testConnection() } }
                    .disabled(selectedService == nil || isTesting)
                Spacer()
                Button("Close") { dismiss() }
            }
        }
        .padding(20)
        .frame(maxHeight: .infinity, alignment: .topLeading)
        .frame(width: 440, height: 300)
    }

    private func testConnection() async {
        guard let service = selectedService else { return }
        errorMessage = nil
        isTesting = true
        let start = Date()
        do {
            let client = TransmissionRPCClient(
                config: service,
                allowInsecureTLS: preferences.allowInsecureTLS
            )
            let response: SessionGetResponseArguments = try await client.request(
                method: "session-get",
                arguments: SessionGetArguments()
            )
            let durationMs = Int(Date().timeIntervalSince(start) * 1000)
            testResult = TestResult(success: true, durationMs: durationMs, version: response.version)
        } catch {
            let durationMs = Int(Date().timeIntervalSince(start) * 1000)
            testResult = TestResult(success: false, durationMs: durationMs, version: nil)
            errorMessage = error.localizedDescription
        }
        isTesting = false
    }

    private var selectedService: ServiceConfig? {
        let configured = serviceStore.service(id: appState.selectedServiceID)
        if let configured {
            return configured
        }
        return serviceStore.services.first
    }
}

private struct TestResult {
    let success: Bool
    let durationMs: Int
    let version: String?
}
