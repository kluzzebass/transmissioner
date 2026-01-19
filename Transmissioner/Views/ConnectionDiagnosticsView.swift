import SwiftUI

struct ConnectionDiagnosticsView: View {
    @EnvironmentObject private var serviceStore: ServiceStore
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var isTesting = false
    @State private var testResult: TestResult?
    @State private var errorMessage: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Connection Diagnostics")
                    .font(.title2.weight(.semibold))
                Spacer()
                if isTesting {
                    ProgressView()
                        .controlSize(.small)
                }
            }

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
            } else {
                Text("No services configured. Add one in Settings.")
                    .foregroundColor(.secondary)
            }

            if let errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundColor(.red)
            }

            if let testResult {
                Form {
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
            }

            HStack {
                Button("Test Connection") { Task { await testConnection() } }
                    .disabled(selectedService == nil || isTesting)
                Spacer()
                Button("Close") { dismiss() }
            }
        }
        .padding(20)
        .frame(minWidth: 480)
    }

    private func testConnection() async {
        guard let service = selectedService else { return }
        errorMessage = nil
        isTesting = true
        let start = Date()
        do {
            let client = TransmissionRPCClient(config: service)
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
