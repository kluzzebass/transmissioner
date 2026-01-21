import Foundation

struct PendingRemoval: Identifiable {
    let id = UUID()
    let service: ServiceConfig
    let torrent: TorrentInfo
    let deleteData: Bool
}
