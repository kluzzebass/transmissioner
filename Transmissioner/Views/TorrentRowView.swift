import AppKit
import SwiftUI

struct TorrentRowView: View {
    let torrent: TorrentInfo
    let globalSeedRatioLimit: Double?
    let globalSeedRatioLimited: Bool
    let compact: Bool
    let onToggle: () -> Void
    let onRequestRemove: () -> Void
    let onRequestRemoveWithData: () -> Void
    let onVerify: () -> Void
    let onReannounce: () -> Void
    let onQueueMoveTop: () -> Void
    let onQueueMoveUp: () -> Void
    let onQueueMoveDown: () -> Void
    let onQueueMoveBottom: () -> Void
    let onSetPriorityLow: () -> Void
    let onSetPriorityNormal: () -> Void
    let onSetPriorityHigh: () -> Void
    let onSetLocation: () -> Void
    let onFileSelection: () -> Void
    let onTrackers: () -> Void
    let onStats: () -> Void
    let onPeers: () -> Void
    let onSeedingLimits: () -> Void
    let onLabels: () -> Void
    let onErrorDetails: () -> Void
    @State private var optionPressed = false
    @State private var flagsMonitor: Any?

    var body: some View {
        VStack(alignment: .leading, spacing: compact ? 4 : 6) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                torrentIcon
                    .foregroundColor(.secondary)
                    .frame(width: 16)
                
                Text(torrent.name)
                    .font(.headline)
                    .lineLimit(1)
                    .help(torrent.name)

                StatusPillView(text: statusText, color: statusColor)

                Spacer()

                Button(action: onToggle) {
                    Image(systemName: torrent.isActive ? "pause.fill" : "play.fill")
                }
                .buttonStyle(.borderless)
                .help(torrent.isActive ? "Pause" : "Start")

                Button(action: removeAction) {
                    Image(systemName: "trash")
                        .foregroundStyle(optionPressed ? Color.red : Color.secondary)
                }
                .buttonStyle(.borderless)
                .help(optionPressed
                      ? "Remove & Delete Data (Option-click)"
                      : "Remove (Option-click to delete data)")
            }

            progressBar

            if let errorText = errorText {
                Text(errorText)
                    .font(.caption)
                    .foregroundColor(.red)
                    .lineLimit(2)
            } else if !compact {
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
        }
        .contextMenu {
            Button(torrent.isActive ? "Pause" : "Start", action: onToggle)
            Button("Verify", action: onVerify)
            Button("Reannounce", action: onReannounce)
            Button("Set Location…", action: onSetLocation)
            Button("File Selection…", action: onFileSelection)
            Button("Trackers…", action: onTrackers)
            Button("Stats…", action: onStats)
            Button("Peers…", action: onPeers)
            Button("Seeding Limits…", action: onSeedingLimits)
            Button("Labels…", action: onLabels)
            Button("Error Details…", action: onErrorDetails)
                .disabled(torrent.errorString?.isEmpty != false)
            Divider()
            Button {
                onSetPriorityHigh()
            } label: {
                Label("Bandwidth Priority: High", systemImage: priorityIcon(1))
            }
            Button {
                onSetPriorityNormal()
            } label: {
                Label("Bandwidth Priority: Normal", systemImage: priorityIcon(0))
            }
            Button {
                onSetPriorityLow()
            } label: {
                Label("Bandwidth Priority: Low", systemImage: priorityIcon(-1))
            }
            Divider()
            Button("Move to Top of Queue", action: onQueueMoveTop)
            Button("Move Up in Queue", action: onQueueMoveUp)
            Button("Move Down in Queue", action: onQueueMoveDown)
            Button("Move to Bottom of Queue", action: onQueueMoveBottom)
            Divider()
            Button("Remove", role: .destructive, action: onRequestRemove)
            Button("Remove & Delete Data", role: .destructive, action: onRequestRemoveWithData)
        }
        .onAppear {
            optionPressed = NSEvent.modifierFlags.contains(.option)
            flagsMonitor = NSEvent.addLocalMonitorForEvents(matching: [.flagsChanged]) { event in
                optionPressed = event.modifierFlags.contains(.option)
                return event
            }
        }
        .onDisappear {
            if let flagsMonitor {
                NSEvent.removeMonitor(flagsMonitor)
                self.flagsMonitor = nil
            }
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

    private var errorText: String? {
        guard let errorString = torrent.errorString, !errorString.isEmpty else { return nil }
        return errorString
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

    private func removeAction() {
        if optionPressed {
            onRequestRemoveWithData()
        } else {
            onRequestRemove()
        }
    }

    private func priorityIcon(_ value: Int) -> String {
        guard let current = torrent.bandwidthPriority else { return "circle" }
        return current == value ? "checkmark.circle.fill" : "circle"
    }

    private var torrentIcon: some View {
        Group {
            if isMagnetRetrievingMetadata {
                Image(systemName: "magnet")
                    .foregroundColor(.red)
            } else if isSingleFile {
                Image(systemName: "doc")
            } else {
                Image(systemName: "folder")
            }
        }
    }

    private var isMagnetRetrievingMetadata: Bool {
        // Magnet links retrieving metadata typically have very low percentDone
        // and the name is often a hash (40 character hex string)
        let hexChars = CharacterSet(charactersIn: "0123456789abcdefABCDEF")
        return torrent.percentDone < 0.01 && torrent.name.count == 40 && torrent.name.unicodeScalars.allSatisfy { hexChars.contains($0) }
    }

    private var isSingleFile: Bool {
        // Heuristic: common single-file extensions
        let singleFileExtensions = ["iso", "zip", "rar", "7z", "tar", "gz", "bz2", "xz", "dmg", "pkg", "deb", "rpm", "exe", "msi", "app", "apk"]
        let nameLower = torrent.name.lowercased()
        return singleFileExtensions.contains { nameLower.hasSuffix(".\($0)") }
    }

    private var progressBar: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(.separator.opacity(0.5))
                Capsule()
                    .fill(progressColor)
                    .frame(width: max(2, width * CGFloat(torrent.percentDone)))
                if let seedOverlayProgress {
                    Capsule()
                        .fill(.white.opacity(0.6))
                        .frame(width: max(2, width * CGFloat(seedOverlayProgress)))
                }
            }
        }
        .frame(minHeight: 6)
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
