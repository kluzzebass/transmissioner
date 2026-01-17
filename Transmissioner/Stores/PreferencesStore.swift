import Combine
import Foundation

final class PreferencesStore: ObservableObject {
    @Published var autoRefresh: Bool {
        didSet { persist() }
    }
    @Published var autoRefreshInterval: Double {
        didSet { persist() }
    }

    private let defaults = UserDefaults.standard
    private let autoRefreshKey = "autoRefresh"
    private let intervalKey = "autoRefreshInterval"

    init() {
        if defaults.object(forKey: autoRefreshKey) != nil {
            autoRefresh = defaults.bool(forKey: autoRefreshKey)
        } else {
            autoRefresh = true
        }

        let storedInterval = defaults.double(forKey: intervalKey)
        autoRefreshInterval = storedInterval > 0 ? storedInterval : 20
    }

    private func persist() {
        defaults.set(autoRefresh, forKey: autoRefreshKey)
        defaults.set(autoRefreshInterval, forKey: intervalKey)
    }
}
