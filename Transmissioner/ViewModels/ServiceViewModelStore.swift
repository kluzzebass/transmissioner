import Combine
import Foundation

@MainActor
final class ServiceViewModelStore: ObservableObject {
    @Published private(set) var viewModels: [UUID: TorrentListViewModel] = [:]

    // Icon state for menu bar indicator
    @Published var hasActiveDownloads = false
    @Published var hasErrors = false
    @Published var hasOfflineServices = false

    // Per-viewModel cancellables for proper cleanup
    private var cancellables: [UUID: AnyCancellable] = [:]

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

        // Observe changes to update icon state
        cancellables[service.id] = Publishers.CombineLatest(
            viewModel.$torrents,
            viewModel.$isOffline
        )
        .sink { [weak self] _, _ in
            Task { @MainActor [weak self] in
                self?.updateIconState()
            }
        }

        return viewModel
    }
    
    private func updateIconState() {
        hasActiveDownloads = viewModels.values.contains { viewModel in
            viewModel.torrents.contains { torrent in
                torrent.status == TransmissionStatus.downloading.rawValue ||
                torrent.status == TransmissionStatus.seeding.rawValue
            }
        }
        
        hasErrors = viewModels.values.contains { viewModel in
            viewModel.torrents.contains { torrent in
                torrent.errorString?.isEmpty == false
            }
        }
        
        hasOfflineServices = viewModels.values.contains { $0.isOffline }
    }

    func removeMissingServices(_ services: [ServiceConfig]) {
        let validIDs = Set(services.map(\.id))
        let removedIDs = Set(viewModels.keys).subtracting(validIDs)

        // Clean up cancellables for removed services
        for id in removedIDs {
            cancellables.removeValue(forKey: id)
        }

        viewModels = viewModels.filter { validIDs.contains($0.key) }
        updateIconState()
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
