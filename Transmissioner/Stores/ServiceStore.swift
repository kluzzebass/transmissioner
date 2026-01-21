import Combine
import Foundation

final class ServiceStore: ObservableObject {
    @Published private(set) var services: [ServiceConfig] = []
    private let defaultsKey = "serviceConfigs"
    private let defaults = UserDefaults.standard

    init() {
        load()
    }

    func service(id: UUID?) -> ServiceConfig? {
        guard let id else { return nil }
        return services.first { $0.id == id }
    }

    func add(_ service: ServiceConfig) {
        KeychainStore.savePassword(service.password, for: service.id)
        services.append(service)
        persist()
    }

    func update(_ service: ServiceConfig) {
        guard let index = services.firstIndex(where: { $0.id == service.id }) else { return }
        KeychainStore.savePassword(service.password, for: service.id)
        services[index] = service
        persist()
    }

    func remove(_ service: ServiceConfig) {
        services.removeAll { $0.id == service.id }
        KeychainStore.deletePassword(for: service.id)
        persist()
    }

    func move(from offsets: IndexSet, to destination: Int) {
        let moving = offsets.map { services[$0] }
        var remaining = services
        for index in offsets.sorted(by: >) {
            remaining.remove(at: index)
        }
        let insertIndex = min(destination, remaining.count)
        remaining.insert(contentsOf: moving, at: insertIndex)
        services = remaining
        persist()
    }

    func replaceAll(_ newServices: [ServiceConfig]) {
        let existingIDs = Set(services.map(\.id))
        let newIDs = Set(newServices.map(\.id))

        let removedIDs = existingIDs.subtracting(newIDs)
        removedIDs.forEach { KeychainStore.deletePassword(for: $0) }

        newServices.forEach { KeychainStore.savePassword($0.password, for: $0.id) }
        services = newServices
        persist()
    }

    private func load() {
        guard let data = defaults.data(forKey: defaultsKey) else {
            services = []
            return
        }
        do {
            let decoded = try JSONDecoder().decode([ServiceConfig].self, from: data)
            services = decoded.map { service in
                var updated = service
                updated.password = KeychainStore.password(for: service.id) ?? ""
                return updated
            }
        } catch {
            services = []
        }
    }

    private func persist() {
        do {
            let data = try JSONEncoder().encode(services)
            defaults.set(data, forKey: defaultsKey)
        } catch {
            defaults.removeObject(forKey: defaultsKey)
        }
    }
}
