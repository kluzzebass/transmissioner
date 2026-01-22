import AppKit
import SwiftUI

struct AddTorrentView: View {
    @State private var magnetLink: String = ""
    @State private var downloadDir: String = ""
    @State private var selectedFileName: String?
    @State private var selectedFileData: Data?
    let onAdd: (String?, Data?, String?) -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Add Torrent")
                .font(.title2.weight(.semibold))

            TextField("Magnet link or URL", text: $magnetLink)
                .textFieldStyle(.roundedBorder)

            HStack(spacing: 8) {
                Button("Choose Torrent File…") {
                    chooseTorrentFile()
                }
                .buttonStyle(.bordered)

                Text(selectedFileName ?? "No file selected")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)

                Spacer()

                if selectedFileData != nil {
                    Button("Clear") {
                        selectedFileName = nil
                        selectedFileData = nil
                    }
                    .buttonStyle(.borderless)
                }
            }

            TextField("Download directory (optional)", text: $downloadDir)
                .textFieldStyle(.roundedBorder)

            HStack {
                Spacer()
                Button("Cancel", action: onCancel)
                Button("Add") {
                    let trimmed = magnetLink.trimmingCharacters(in: .whitespacesAndNewlines)
                    onAdd(trimmed.isEmpty ? nil : trimmed, selectedFileData, downloadDir.isEmpty ? nil : downloadDir)
                }
                .keyboardShortcut(.defaultAction)
                .disabled(selectedFileData == nil && magnetLink.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(20)
        .frame(minWidth: 500)
    }

    private func chooseTorrentFile() {
        let panel = NSOpenPanel()
        panel.allowedFileTypes = ["torrent"]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true

        if panel.runModal() == .OK, let url = panel.url {
            if let data = try? Data(contentsOf: url) {
                selectedFileData = data
                selectedFileName = url.lastPathComponent
                magnetLink = ""
            }
        }
    }
}
