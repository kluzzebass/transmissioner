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
        services.append(service)
        persist()
    }

    func update(_ service: ServiceConfig) {
        guard let index = services.firstIndex(where: { $0.id == service.id }) else { return }
        services[index] = service
        persist()
    }

    func remove(_ service: ServiceConfig) {
        services.removeAll { $0.id == service.id }
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

    private func load() {
        guard let data = defaults.data(forKey: defaultsKey) else {
            services = []
            return
        }
        do {
            services = try JSONDecoder().decode([ServiceConfig].self, from: data)
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
