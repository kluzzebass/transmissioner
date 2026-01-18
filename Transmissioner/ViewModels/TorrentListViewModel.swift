import Combine
import Foundation
import SwiftUI

@MainActor
final class TorrentListViewModel: ObservableObject {
    @Published var torrents: [TorrentInfo] = []
    @Published var isLoading = false
    @Published var lastError: String?
    @Published var lastUpdated: Date?
    @Published var sessionSeedRatioLimit: Double?
    @Published var sessionSeedRatioLimited = false
    @Published var altSpeedEnabled = false

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
        isLoading = torrents.isEmpty
        defer {
            isLoading = false
            lastUpdated = Date()
        }

        do {
            let response: TorrentGetResponseArguments = try await client.request(
                method: "torrent-get",
                arguments: TorrentGetArguments(fields: TorrentInfo.defaultFields, ids: nil)
            )
            let sorted = response.torrents.sorted(by: { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending })
            applyInPlaceUpdates(sorted)
            lastError = nil
            do {
                let session: SessionGetResponseArguments = try await client.request(
                    method: "session-get",
                    arguments: SessionGetArguments()
                )
                sessionSeedRatioLimit = session.seedRatioLimit
                sessionSeedRatioLimited = session.seedRatioLimited ?? false
                altSpeedEnabled = session.altSpeedEnabled ?? false
            } catch {
                sessionSeedRatioLimit = nil
                sessionSeedRatioLimited = false
                altSpeedEnabled = false
            }
        } catch {
            lastError = error.localizedDescription
        }
    }

    private func applyInPlaceUpdates(_ incoming: [TorrentInfo]) {
        var incomingById: [Int: TorrentInfo] = [:]
        incomingById.reserveCapacity(incoming.count)
        incoming.forEach { incomingById[$0.id] = $0 }

        var removedIndices: [Int] = []
        removedIndices.reserveCapacity(max(0, torrents.count - incoming.count))

        for index in torrents.indices {
            let current = torrents[index]
            if let updated = incomingById.removeValue(forKey: current.id) {
                if updated != current {
                    torrents[index] = updated
                }
            } else {
                removedIndices.append(index)
            }
        }

        if !removedIndices.isEmpty {
            for index in removedIndices.sorted(by: >) {
                torrents.remove(at: index)
            }
        }

        if !incomingById.isEmpty {
            torrents.append(contentsOf: incomingById.values)
        }

        if torrents.count != incoming.count || !isSortedByName(torrents) {
            withAnimation(.none) {
                torrents = incoming
            }
        }
    }

    private func isSortedByName(_ list: [TorrentInfo]) -> Bool {
        guard list.count > 1 else { return true }
        for (lhs, rhs) in zip(list, list.dropFirst()) {
            if lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedDescending {
                return false
            }
        }
        return true
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

    func setAltSpeed(enabled: Bool) async {
        guard let client else { return }
        do {
            let _: EmptyResponse = try await client.request(
                method: "session-set",
                arguments: SessionAltSpeedArguments(altSpeedEnabled: enabled)
            )
            altSpeedEnabled = enabled
        } catch {
            lastError = error.localizedDescription
        }
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
