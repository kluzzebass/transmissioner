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
