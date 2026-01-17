import SwiftUI

struct TorrentRowView: View {
    let torrent: TorrentInfo
    let globalSeedRatioLimit: Double?
    let globalSeedRatioLimited: Bool
    let onToggle: () -> Void
    let onRemove: () -> Void
    let onRemoveWithData: () -> Void
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

            progressBar

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
            Button("Remove & Delete Data", role: .destructive, action: onRemoveWithData)
        }
    }

    private var statusText: String {
        switch displayState {
        case .error:
            return "Error"
        case .stopped:
            return "Stopped"
        case .checking:
            return "Checking"
        case .downloading:
            return "Downloading"
        case .completed:
            return "Completed"
        case .seeding:
            return "Seeding"
        case .seedingComplete:
            return "Seeding Complete"
        case .unknown:
            return "Unknown"
        }
    }

    private var statusColor: Color {
        switch displayState {
        case .error:
            return .red
        case .stopped:
            return .gray
        case .checking:
            return .orange
        case .downloading:
            return .blue
        case .completed:
            return .purple
        case .seeding:
            return .teal
        case .seedingComplete:
            return .green
        case .unknown:
            return .gray
        }
    }

    private var progressColor: Color {
        switch displayState {
        case .completed, .seeding:
            return .green
        case .seedingComplete, .downloading, .checking, .stopped, .unknown:
            return .gray
        case .error:
            return .red
        }
    }

    private var progressBar: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.gray.opacity(0.2))
                Capsule()
                    .fill(progressColor)
                    .frame(width: max(2, width * CGFloat(torrent.percentDone)))
                if let seedOverlayProgress {
                    Capsule()
                        .fill(Color.green.opacity(0.5))
                        .frame(width: max(2, width * CGFloat(seedOverlayProgress)))
                }
            }
        }
        .frame(height: 6)
    }

    private var seedOverlayProgress: Double? {
        guard displayState == .seeding else { return nil }
        guard let limit = resolvedSeedRatioLimit else { return nil }
        let progress = torrent.uploadRatio / limit
        return min(max(progress, 0), 1)
    }

    private enum DisplayState {
        case error
        case stopped
        case checking
        case downloading
        case completed
        case seeding
        case seedingComplete
        case unknown
    }

    private var displayState: DisplayState {
        if let errorString = torrent.errorString, !errorString.isEmpty {
            return .error
        }
        guard let status = TransmissionStatus(rawValue: torrent.status) else {
            return .unknown
        }
        switch status {
        case .stopped:
            return torrent.isFinished ? .completed : .stopped
        case .checkWait, .checking:
            return .checking
        case .downloadWait, .downloading:
            return .downloading
        case .seedWait, .seeding:
            if let limit = resolvedSeedRatioLimit, torrent.uploadRatio >= limit {
                return .seedingComplete
            }
            return .seeding
        }
    }

    private var resolvedSeedRatioLimit: Double? {
        if torrent.seedRatioMode == 1, let limit = torrent.seedRatioLimit, limit > 0 {
            return limit
        }
        if torrent.seedRatioMode == 0 || torrent.seedRatioMode == nil {
            guard globalSeedRatioLimited, let limit = globalSeedRatioLimit, limit > 0 else { return nil }
            return limit
        }
        return nil
    }
}
