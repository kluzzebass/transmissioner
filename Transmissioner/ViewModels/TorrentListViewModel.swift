import Combine
import Foundation

@MainActor
final class TorrentListViewModel: ObservableObject {
    @Published var torrents: [TorrentInfo] = []
    @Published var isLoading = false
    @Published var lastError: String?
    @Published var lastUpdated: Date?

    private var client: TransmissionRPCClient?
    private var currentConfig: ServiceConfig?

    func configure(with config: ServiceConfig?) {
        guard currentConfig != config else { return }
        currentConfig = config
        client = config.map { TransmissionRPCClient(config: $0) }
        torrents = []
        lastError = nil
        if config != nil {
            Task { await refresh() }
        }
    }

    func refresh() async {
        guard let client else { return }
        isLoading = true
        defer {
            isLoading = false
            lastUpdated = Date()
        }

        do {
            let response: TorrentGetResponseArguments = try await client.request(
                method: "torrent-get",
                arguments: TorrentGetArguments(fields: TorrentInfo.defaultFields, ids: nil)
            )
            torrents = response.torrents.sorted(by: { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending })
            lastError = nil
        } catch {
            lastError = error.localizedDescription
        }
    }

    func start(ids: [Int]? = nil) async {
        await runAction(method: "torrent-start", arguments: TorrentActionArguments(ids: ids))
    }

    func stop(ids: [Int]? = nil) async {
        await runAction(method: "torrent-stop", arguments: TorrentActionArguments(ids: ids))
    }

    func verify(ids: [Int]) async {
        await runAction(method: "torrent-verify", arguments: TorrentActionArguments(ids: ids))
    }

    func reannounce(ids: [Int]) async {
        await runAction(method: "torrent-reannounce", arguments: TorrentActionArguments(ids: ids))
    }

    func remove(ids: [Int], deleteData: Bool) async {
        await runAction(method: "torrent-remove", arguments: TorrentRemoveArguments(ids: ids, deleteLocalData: deleteData))
    }

    func addTorrent(magnetLink: String, downloadDir: String?) async {
        guard let client else { return }
        do {
            let _: EmptyResponse = try await client.request(
                method: "torrent-add",
                arguments: TorrentAddArguments(filename: magnetLink, downloadDir: downloadDir)
            )
            await refresh()
        } catch {
            lastError = error.localizedDescription
        }
    }

    func testConnection() async -> Result<SessionGetResponseArguments, Error> {
        guard let client else {
            return .failure(TransmissionRPCError.invalidURL)
        }
        do {
            let response: SessionGetResponseArguments = try await client.request(
                method: "session-get",
                arguments: SessionGetArguments()
            )
            return .success(response)
        } catch {
            return .failure(error)
        }
    }

    private func runAction<Arguments: Encodable>(method: String, arguments: Arguments) async {
        guard let client else { return }
        do {
            let _: EmptyResponse = try await client.request(method: method, arguments: arguments)
            await refresh()
        } catch {
            lastError = error.localizedDescription
        }
    }
}
