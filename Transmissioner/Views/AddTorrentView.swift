import SwiftUI

struct AddTorrentView: View {
    @State private var magnetLink: String = ""
    @State private var downloadDir: String = ""
    let onAdd: (String, String?) -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Add Torrent")
                .font(.title2.weight(.semibold))

            TextField("Magnet link or URL", text: $magnetLink)
                .textFieldStyle(.roundedBorder)

            TextField("Download directory (optional)", text: $downloadDir)
                .textFieldStyle(.roundedBorder)

            HStack {
                Spacer()
                Button("Cancel", action: onCancel)
                Button("Add") {
                    onAdd(magnetLink, downloadDir.isEmpty ? nil : downloadDir)
                }
                .keyboardShortcut(.defaultAction)
                .disabled(magnetLink.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(20)
        .frame(minWidth: 500)
    }
}
