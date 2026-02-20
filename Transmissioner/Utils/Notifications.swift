import Foundation

extension Notification.Name {
    static let showAddTorrent = Notification.Name("Transmissioner.showAddTorrent")
    static let refreshTorrents = Notification.Name("Transmissioner.refreshTorrents")
    static let toggleCompactView = Notification.Name("Transmissioner.toggleCompactView")
    static let addMagnetLink = Notification.Name("Transmissioner.addMagnetLink")
    static let openSettingsWindow = Notification.Name("Transmissioner.openSettingsWindow")
}

extension Notification {
    static let magnetLinkKey = "magnetLink"
}
