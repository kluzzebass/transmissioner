import SwiftUI

struct FreeSpaceView: View {
    @EnvironmentObject private var serviceStore: ServiceStore
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var path: String = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var freeSpace: String = "—"
    @State private var resolvedPath: String = "—"

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Free Space")
                    .font(.title2.weight(.semibold))
                Spacer()
                if isLoading {
                    ProgressView()
                        .controlSize(.small)
                }
            }

            Text("Path on the remote server")
                .font(.headline)

            TextField("e.g. /data/media/downloads", text: $path)
                .textFieldStyle(.roundedBorder)

            if let errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundColor(.red)
            }

            Form {
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

            HStack {
                Spacer()
                Button("Close") { dismiss() }
                Button("Lookup") { Task { await lookup() } }
                    .buttonStyle(.borderedProminent)
                    .disabled(path.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(20)
        .frame(minWidth: 460)
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
            let client = TransmissionRPCClient(config: service)
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
