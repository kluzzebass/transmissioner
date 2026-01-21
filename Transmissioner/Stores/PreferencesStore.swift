import Combine
import Foundation

final class PreferencesStore: ObservableObject {
    @Published var autoRefresh: Bool {
        didSet { persist() }
    }
    @Published var autoRefreshInterval: Double {
        didSet { persist() }
    }
    @Published var compactView: Bool {
        didSet { persist() }
    }
    @Published var allowInsecureTLS: Bool {
        didSet { persist() }
    }

    private let defaults = UserDefaults.standard
    private let autoRefreshKey = "autoRefresh"
    private let intervalKey = "autoRefreshInterval"
    private let compactViewKey = "compactView"
    private let allowInsecureTLSKey = "allowInsecureTLS"

    init() {
        if defaults.object(forKey: autoRefreshKey) != nil {
            autoRefresh = defaults.bool(forKey: autoRefreshKey)
        } else {
            autoRefresh = true
        }

        let storedInterval = defaults.double(forKey: intervalKey)
        autoRefreshInterval = storedInterval > 0 ? storedInterval : 20

        if defaults.object(forKey: compactViewKey) != nil {
            compactView = defaults.bool(forKey: compactViewKey)
        } else {
            compactView = false
        }

        if defaults.object(forKey: allowInsecureTLSKey) != nil {
            allowInsecureTLS = defaults.bool(forKey: allowInsecureTLSKey)
        } else {
            allowInsecureTLS = false
        }
    }

    private func persist() {
        defaults.set(autoRefresh, forKey: autoRefreshKey)
        defaults.set(autoRefreshInterval, forKey: intervalKey)
        defaults.set(compactView, forKey: compactViewKey)
        defaults.set(allowInsecureTLS, forKey: allowInsecureTLSKey)
    }
}
