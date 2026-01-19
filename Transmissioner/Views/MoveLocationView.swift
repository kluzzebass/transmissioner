import SwiftUI

struct MoveLocationView: View {
    @EnvironmentObject private var serviceStore: ServiceStore
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var location = ""
    @State private var moveData = true
    @State private var isSubmitting = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Set Location")
                .font(.title2.weight(.semibold))

            VStack(alignment: .leading, spacing: 8) {
                Text("Destination path on the remote server")
                    .font(.headline)

                TextField("e.g. /data/media/downloads", text: $location)
                    .textFieldStyle(.roundedBorder)
            }

            Toggle("Move data to new location", isOn: $moveData)

            if let errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundColor(.red)
            }

            HStack {
                Spacer()
                Button("Cancel") {
                    dismiss()
                }
                Button(isSubmitting ? "Working…" : "OK") {
                    Task { await submit() }
                }
                .buttonStyle(.borderedProminent)
                .disabled(isSubmitting || location.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(20)
        .frame(minWidth: 480)
    }

    private func submit() async {
        guard let service = selectedService else {
            errorMessage = "Select a service before changing location."
            return
        }
        let ids = appState.moveLocationTorrentIDs
        guard !ids.isEmpty else {
            errorMessage = "Select a torrent to move."
            return
        }
        let trimmed = location.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        errorMessage = nil
        isSubmitting = true
        defer { isSubmitting = false }

        do {
            let client = TransmissionRPCClient(config: service)
            let _: EmptyResponse = try await client.request(
                method: "torrent-set-location",
                arguments: TorrentSetLocationArguments(ids: ids, location: trimmed, move: moveData)
            )
            dismiss()
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
