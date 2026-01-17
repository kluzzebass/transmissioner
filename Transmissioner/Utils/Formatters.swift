import Foundation

enum Formatters {
    static let byteCount: ByteCountFormatter = {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useGB, .useMB, .useKB]
        formatter.countStyle = .file
        formatter.includesUnit = true
        formatter.isAdaptive = true
        return formatter
    }()

    static let rateCount: ByteCountFormatter = {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useGB, .useMB, .useKB]
        formatter.countStyle = .binary
        formatter.includesUnit = true
        formatter.isAdaptive = true
        return formatter
    }()

    static func rateString(_ bytesPerSecond: Int) -> String {
        guard bytesPerSecond > 0 else { return "0 B/s" }
        return "\(rateCount.string(fromByteCount: Int64(bytesPerSecond)))/s"
    }

    static func percentString(_ value: Double) -> String {
        let percent = max(0, min(1, value)) * 100
        return String(format: "%.0f%%", percent)
    }

    static func etaString(_ seconds: Int) -> String {
        guard seconds >= 0 else { return "—" }
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }
}
