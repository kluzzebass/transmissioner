import SwiftUI

struct TorrentRowView: View {
    let torrent: TorrentInfo
    let onToggle: () -> Void
    let onRemove: () -> Void
    let onVerify: () -> Void
    let onReannounce: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(torrent.name)
                    .font(.headline)
                    .lineLimit(1)

                StatusPillView(text: statusText, color: statusColor)

                Spacer()

                Button(action: onToggle) {
                    Image(systemName: torrent.isActive ? "pause.fill" : "play.fill")
                }
                .buttonStyle(.borderless)
                .help(torrent.isActive ? "Pause" : "Start")
            }

            ProgressView(value: torrent.percentDone)
                .progressViewStyle(.linear)

            HStack(spacing: 12) {
                Text(Formatters.percentString(torrent.percentDone))
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text("DL \(Formatters.rateString(torrent.rateDownload))")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text("UL \(Formatters.rateString(torrent.rateUpload))")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text("ETA \(Formatters.etaString(torrent.eta))")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()
            }
        }
        .contextMenu {
            Button(torrent.isActive ? "Pause" : "Start", action: onToggle)
            Button("Verify", action: onVerify)
            Button("Reannounce", action: onReannounce)
            Divider()
            Button("Remove", role: .destructive, action: onRemove)
        }
    }

    private var statusText: String {
        if let errorString = torrent.errorString, !errorString.isEmpty {
            return "Error"
        }
        guard let status = TransmissionStatus(rawValue: torrent.status) else {
            return "Unknown"
        }
        switch status {
        case .stopped:
            return "Stopped"
        case .checkWait, .checking:
            return "Checking"
        case .downloadWait, .downloading:
            return "Downloading"
        case .seedWait, .seeding:
            return "Seeding"
        }
    }

    private var statusColor: Color {
        if let errorString = torrent.errorString, !errorString.isEmpty {
            return .red
        }
        guard let status = TransmissionStatus(rawValue: torrent.status) else {
            return .gray
        }
        switch status {
        case .stopped:
            return .gray
        case .checkWait, .checking:
            return .orange
        case .downloadWait, .downloading:
            return .blue
        case .seedWait, .seeding:
            return .green
        }
    }
}
