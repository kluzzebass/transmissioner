import Combine
import Foundation

@MainActor
final class ServiceViewModelStore: ObservableObject {
    @Published private(set) var viewModels: [UUID: TorrentListViewModel] = [:]

    func viewModel(for service: ServiceConfig, allowInsecureTLS: Bool) -> TorrentListViewModel {
        if let existing = viewModels[service.id] {
            existing.allowInsecureTLS = allowInsecureTLS
            existing.configure(with: service)
            return existing
        }

        let viewModel = TorrentListViewModel()
        viewModel.allowInsecureTLS = allowInsecureTLS
        viewModel.configure(with: service)
        viewModels[service.id] = viewModel
        return viewModel
    }

    func removeMissingServices(_ services: [ServiceConfig]) {
        let validIDs = Set(services.map(\.id))
        viewModels = viewModels.filter { validIDs.contains($0.key) }
    }

    func refreshAll() async {
        for viewModel in viewModels.values {
            await viewModel.refresh()
        }
    }

    func startAll() async {
        for viewModel in viewModels.values {
            await viewModel.start()
        }
    }

    func stopAll() async {
        for viewModel in viewModels.values {
            await viewModel.stop()
        }
    }

    func setAltSpeed(enabled: Bool) async {
        for viewModel in viewModels.values {
            await viewModel.setAltSpeed(enabled: enabled)
        }
    }

    var anyAltSpeedEnabled: Bool {
        viewModels.values.contains { $0.altSpeedEnabled }
    }

    var allAltSpeedEnabled: Bool {
        !viewModels.isEmpty && viewModels.values.allSatisfy { $0.altSpeedEnabled }
    }
}
