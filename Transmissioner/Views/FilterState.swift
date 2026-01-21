import Combine
import Foundation

enum StatusFilter: String, CaseIterable, Identifiable {
    case all
    case downloading
    case seeding
    case completed
    case stopped
    case error

    var id: String { rawValue }

    var label: String {
        switch self {
        case .all: return "All"
        case .downloading: return "Downloading"
        case .seeding: return "Seeding"
        case .completed: return "Completed"
        case .stopped: return "Stopped"
        case .error: return "Error"
        }
    }

    func matches(_ torrent: TorrentInfo) -> Bool {
        switch self {
        case .all:
            return true
        case .error:
            return (torrent.errorString?.isEmpty == false)
        case .downloading:
            return torrent.status == TransmissionStatus.downloading.rawValue
        case .seeding:
            return torrent.status == TransmissionStatus.seeding.rawValue
        case .completed:
            return torrent.isFinished
        case .stopped:
            return torrent.status == TransmissionStatus.stopped.rawValue
        }
    }
}

enum SortOrder: String, CaseIterable, Identifiable {
    case name
    case progress
    case eta
    case activity

    var id: String { rawValue }

    var label: String {
        switch self {
        case .name: return "Name"
        case .progress: return "Progress"
        case .eta: return "ETA"
        case .activity: return "Active"
        }
    }
}

final class FilterState: ObservableObject {
    @Published var searchText = ""
    @Published var statusFilter: StatusFilter = .all
    @Published var sortOrder: SortOrder = .name
}
