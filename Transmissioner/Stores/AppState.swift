import Combine
import Foundation

final class AppState: ObservableObject {
    @Published var selectedServiceID: UUID? {
        didSet {
            defaults.set(selectedServiceID?.uuidString, forKey: selectedServiceKey)
        }
    }
    @Published var moveLocationTorrentIDs: [Int] = []
    @Published var fileSelectionTorrentID: Int?
    @Published var trackersTorrentID: Int?
    @Published var statsTorrentID: Int?
    @Published var peersTorrentID: Int?
    @Published var seedingLimitsTorrentID: Int?
    @Published var labelsTorrentID: Int?
    @Published var errorDetailsTorrentID: Int?
    @Published var serverSettingsSection: String?
    @Published var settingsTab: String?
    @Published var pendingMagnetLink: String?
    @Published var pendingTorrentFileData: Data?
    @Published var pendingTorrentFileURL: URL?

    private let defaults = UserDefaults.standard
    private let selectedServiceKey = "selectedServiceID"

    init() {
        if let stored = defaults.string(forKey: selectedServiceKey) {
            selectedServiceID = UUID(uuidString: stored)
        } else {
            selectedServiceID = nil
        }
    }
}
