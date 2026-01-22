import SwiftUI

struct FreeSpaceView: View {
    @EnvironmentObject private var serviceStore: ServiceStore
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var preferences: PreferencesStore
    @Environment(\.dismiss) private var dismiss
    @State private var path: String = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var freeSpace: String = "—"
    @State private var resolvedPath: String = "—"

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Spacer()
                if isLoading {
                    ProgressView()
                        .controlSize(.small)
                }
            }

            GroupBox("Lookup") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Path on the remote server")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    TextField("e.g. /data/media/downloads", text: $path)
                        .textFieldStyle(.roundedBorder)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            if let errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundColor(.red)
            }

            GroupBox("Results") {
                VStack(alignment: .leading, spacing: 10) {
                    LabeledContent("Free space") {
                        Text(freeSpace)
                            .monospacedDigit()
                    }
                    LabeledContent("Resolved path") {
                        Text(resolvedPath)
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
                Button("Lookup") { Task { await lookup() } }
                    .buttonStyle(.borderedProminent)
                    .disabled(path.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(20)
        .frame(maxHeight: .infinity, alignment: .topLeading)
    }

    private func lookup() async {
        guard let service = selectedService else {
            errorMessage = "Select a service to lookup free space."
            return
        }

        let trimmed = path.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        errorMessage = nil
        isLoading = true
        defer { isLoading = false }

        do {
            let client = TransmissionRPCClient(
                config: service,
                allowInsecureTLS: preferences.allowInsecureTLS
            )
            let response: FreeSpaceResponseArguments = try await client.request(
                method: "free-space",
                arguments: FreeSpaceArguments(path: trimmed)
            )
            freeSpace = Formatters.sizeString(response.sizeBytes)
            resolvedPath = response.path
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
