import Combine
import Foundation

final class AppState: ObservableObject {
    @Published var selectedServiceID: UUID? {
        didSet {
            defaults.set(selectedServiceID?.uuidString, forKey: selectedServiceKey)
        }
    }

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
