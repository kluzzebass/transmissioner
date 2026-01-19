import SwiftUI

struct BlocklistView: View {
    @EnvironmentObject private var serviceStore: ServiceStore
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var blocklistEnabled = false
    @State private var blocklistURL: String = ""
    @State private var blocklistSize: Int = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Blocklist")
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
                Toggle("Enable blocklist", isOn: $blocklistEnabled)
                LabeledContent("Blocklist URL") {
                    TextField("", text: $blocklistURL)
                        .textFieldStyle(.roundedBorder)
                        .frame(minWidth: 240)
                }
                LabeledContent("Entries") {
                    Text("\(blocklistSize)")
                        .monospacedDigit()
                }
            }

            HStack {
                Button("Update Now") { Task { await updateBlocklist() } }
                Spacer()
                Button("Cancel") { dismiss() }
                Button("OK") { Task { await save() } }
                    .buttonStyle(.borderedProminent)
            }
        }
        .padding(20)
        .frame(minWidth: 480)
        .onAppear(perform: load)
        .onChange(of: appState.selectedServiceID) { _, _ in load() }
    }

    private func load() {
        guard let service = selectedService else {
            errorMessage = "Select a service to edit blocklist settings."
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
                blocklistEnabled = response.blocklistEnabled ?? false
                blocklistURL = response.blocklistURL ?? ""
                blocklistSize = response.blocklistSize ?? 0
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    private func save() async {
        guard let service = selectedService else { return }
        let trimmedURL = blocklistURL.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedURL.isEmpty else {
            errorMessage = "Blocklist URL is required."
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            let client = TransmissionRPCClient(config: service)
            let args = SessionSetBlocklistArguments(blocklistEnabled: blocklistEnabled, blocklistURL: trimmedURL)
            let _: EmptyResponse = try await client.request(method: "session-set", arguments: args)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func updateBlocklist() async {
        guard let service = selectedService else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            let client = TransmissionRPCClient(config: service)
            let response: BlocklistUpdateResponseArguments = try await client.request(
                method: "blocklist-update",
                arguments: EmptyArguments()
            )
            blocklistSize = response.blocklistSize
        } catch {
            errorMessage = error.localizedDescription
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
