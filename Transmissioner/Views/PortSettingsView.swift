import SwiftUI

struct PortSettingsView: View {
    @EnvironmentObject private var serviceStore: ServiceStore
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var preferences: PreferencesStore
    @Environment(\.dismiss) private var dismiss
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var peerPort: Int = 51413
    @State private var randomOnStart = false
    @State private var portOpen: Bool?

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

            GroupBox("Port") {
                VStack(alignment: .leading, spacing: 8) {
                    Stepper(value: $peerPort, in: 1...65_535) {
                        LabeledContent("Peer port", value: "\(peerPort)")
                            .monospacedDigit()
                    }
                    Toggle("Randomize port on start", isOn: $randomOnStart)
                }
            }

            GroupBox("Status") {
                HStack {
                    LabeledContent("Port status") {
                        Text(portStatusText)
                            .foregroundColor(portStatusColor)
                    }
                    Spacer()
                    Button("Test Port") { Task { await testPort() } }
                }
            }

            Spacer()

            HStack {
                Spacer()
                Button("Cancel") { dismiss() }
                Button("OK") { Task { await save() } }
                    .buttonStyle(.borderedProminent)
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
            errorMessage = "Select a service to edit port settings."
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
                peerPort = response.peerPort ?? peerPort
                randomOnStart = response.peerPortRandomOnStart ?? false
                portOpen = response.portIsOpen
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    private func save() async {
        guard let service = selectedService else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            let client = TransmissionRPCClient(
                config: service,
                allowInsecureTLS: preferences.allowInsecureTLS
            )
            let args = SessionSetPortArguments(peerPort: peerPort, peerPortRandomOnStart: randomOnStart)
            let _: EmptyResponse = try await client.request(method: "session-set", arguments: args)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func testPort() async {
        guard let service = selectedService else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            let client = TransmissionRPCClient(
                config: service,
                allowInsecureTLS: preferences.allowInsecureTLS
            )
            let response: PortTestResponseArguments = try await client.request(
                method: "port-test",
                arguments: EmptyArguments()
            )
            portOpen = response.portIsOpen
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private var portStatusText: String {
        switch portOpen {
        case true: return "Open"
        case false: return "Closed"
        default: return "Unknown"
        }
    }

    private var portStatusColor: Color {
        switch portOpen {
        case true: return .green
        case false: return .red
        default: return .secondary
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
