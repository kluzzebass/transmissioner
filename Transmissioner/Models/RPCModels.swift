import Foundation

struct RPCRequest<Arguments: Encodable>: Encodable {
    let method: String
    let arguments: Arguments?
    let tag: Int?
}

struct RPCResponse<Arguments: Decodable>: Decodable {
    let result: String
    let arguments: Arguments?
    let tag: Int?
}

struct EmptyArguments: Encodable {}
struct EmptyResponse: Decodable {}

struct TorrentGetArguments: Encodable {
    let fields: [String]
    let ids: [Int]?
}

struct TorrentGetResponseArguments: Decodable {
    let torrents: [TorrentInfo]
    let removed: [Int]?
}

struct TorrentGetFilesResponseArguments: Decodable {
    let torrents: [TorrentFileInfo]
}

struct TorrentFileInfo: Decodable {
    let id: Int
    let name: String
    let files: [TorrentFile]
    let fileStats: [TorrentFileStat]
}

struct TorrentFile: Decodable {
    let name: String
    let length: Int
    let bytesCompleted: Int

    enum CodingKeys: String, CodingKey {
        case name
        case length
        case bytesCompleted = "bytesCompleted"
    }
}

struct TorrentFileStat: Decodable {
    let wanted: Bool
    let priority: Int
}

struct TorrentGetTrackersResponseArguments: Decodable {
    let torrents: [TorrentTrackerInfo]
}

struct TorrentTrackerInfo: Decodable {
    let id: Int
    let name: String
    let trackers: [TorrentTracker]
}

struct TorrentTracker: Decodable, Identifiable {
    let id: Int
    let announce: String
    let scrape: String
    let tier: Int
}

struct TorrentStatsResponseArguments: Decodable {
    let torrents: [TorrentStatsInfo]
}

struct TorrentStatsInfo: Decodable {
    let id: Int
    let name: String
    let totalSize: Int
    let downloadedEver: Int
    let uploadedEver: Int
    let corruptEver: Int
    let addedDate: Int
    let doneDate: Int
    let activityDate: Int
    let startDate: Int
    let secondsDownloading: Int
    let secondsSeeding: Int
    let peersConnected: Int
    let peersSendingToUs: Int
    let peersGettingFromUs: Int
    let seedRatioLimit: Double?
    let seedRatioMode: Int?
}

struct TorrentPeersResponseArguments: Decodable {
    let torrents: [TorrentPeersInfo]
}

struct TorrentPeersInfo: Decodable {
    let id: Int
    let name: String
    let peers: [TorrentPeer]
    let peersFrom: [String: Int]
}

struct TorrentPeer: Decodable, Identifiable {
    let address: String
    let clientName: String
    let progress: Double
    let rateToClient: Int
    let rateToPeer: Int
    let flagStr: String

    var id: String { address }
}

struct TorrentSeedLimitsResponseArguments: Decodable {
    let torrents: [TorrentSeedLimitsInfo]
}

struct TorrentSeedLimitsInfo: Decodable {
    let id: Int
    let name: String
    let seedRatioLimit: Double?
    let seedRatioMode: Int
    let seedIdleLimit: Int?
    let seedIdleMode: Int
}

struct TorrentActionArguments: Encodable {
    let ids: [Int]?
}

struct TorrentRemoveArguments: Encodable {
    let ids: [Int]
    let deleteLocalData: Bool

    enum CodingKeys: String, CodingKey {
        case ids
        case deleteLocalData = "delete-local-data"
    }
}

struct TorrentSetArguments: Encodable {
    let ids: [Int]
    let bandwidthPriority: Int

    enum CodingKeys: String, CodingKey {
        case ids
        case bandwidthPriority = "bandwidthPriority"
    }
}

struct TorrentSetFilesArguments: Encodable {
    let ids: [Int]
    let filesWanted: [Int]?
    let filesUnwanted: [Int]?
    let priorityHigh: [Int]?
    let priorityNormal: [Int]?
    let priorityLow: [Int]?

    enum CodingKeys: String, CodingKey {
        case ids
        case filesWanted = "files-wanted"
        case filesUnwanted = "files-unwanted"
        case priorityHigh = "priority-high"
        case priorityNormal = "priority-normal"
        case priorityLow = "priority-low"
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(ids, forKey: .ids)
        if let filesWanted = filesWanted, !filesWanted.isEmpty {
            try container.encode(filesWanted, forKey: .filesWanted)
        }
        if let filesUnwanted = filesUnwanted, !filesUnwanted.isEmpty {
            try container.encode(filesUnwanted, forKey: .filesUnwanted)
        }
        if let priorityHigh = priorityHigh, !priorityHigh.isEmpty {
            try container.encode(priorityHigh, forKey: .priorityHigh)
        }
        if let priorityNormal = priorityNormal, !priorityNormal.isEmpty {
            try container.encode(priorityNormal, forKey: .priorityNormal)
        }
        if let priorityLow = priorityLow, !priorityLow.isEmpty {
            try container.encode(priorityLow, forKey: .priorityLow)
        }
    }
}

struct TorrentSetTrackersArguments: Encodable {
    let ids: [Int]
    let trackerAdd: [String]?
    let trackerRemove: [Int]?

    enum CodingKeys: String, CodingKey {
        case ids
        case trackerAdd = "trackerAdd"
        case trackerRemove = "trackerRemove"
    }
}

struct TorrentSetLocationArguments: Encodable {
    let ids: [Int]
    let location: String
    let move: Bool

    enum CodingKeys: String, CodingKey {
        case ids
        case location
        case move
    }
}

struct TorrentSetSeedLimitsArguments: Encodable {
    let ids: [Int]
    let seedRatioLimit: Double?
    let seedRatioMode: Int
    let seedIdleLimit: Int?
    let seedIdleMode: Int

    enum CodingKeys: String, CodingKey {
        case ids
        case seedRatioLimit = "seedRatioLimit"
        case seedRatioMode = "seedRatioMode"
        case seedIdleLimit = "seedIdleLimit"
        case seedIdleMode = "seedIdleMode"
    }
}

struct TorrentLabelsResponseArguments: Decodable {
    let torrents: [TorrentLabelsInfo]
}

struct TorrentLabelsInfo: Decodable {
    let id: Int
    let name: String
    let labels: [String]
}

struct TorrentSetLabelsArguments: Encodable {
    let ids: [Int]
    let labels: [String]
}

struct TorrentErrorResponseArguments: Decodable {
    let torrents: [TorrentErrorInfo]
}

struct TorrentErrorInfo: Decodable {
    let id: Int
    let name: String
    let error: Int?
    let errorString: String?
    let activityDate: Int?
}

struct TorrentAddArguments: Encodable {
    let filename: String?
    let metainfo: String?
    let downloadDir: String?

    enum CodingKeys: String, CodingKey {
        case filename
        case metainfo
        case downloadDir = "download-dir"
    }
}

struct SessionGetArguments: Encodable {}

struct SessionGetResponseArguments: Decodable {
    let version: String?
    let downloadDir: String?
    let seedRatioLimit: Double?
    let seedRatioLimited: Bool?
    let altSpeedEnabled: Bool?
    let altSpeedTimeEnabled: Bool?
    let altSpeedTimeBegin: Int?
    let altSpeedTimeEnd: Int?
    let altSpeedTimeDay: Int?
    let speedLimitDown: Int?
    let speedLimitDownEnabled: Bool?
    let speedLimitUp: Int?
    let speedLimitUpEnabled: Bool?
    let encryption: String?
    let peerLimitGlobal: Int?
    let peerLimitPerTorrent: Int?
    let blocklistEnabled: Bool?
    let blocklistURL: String?
    let blocklistSize: Int?
    let peerPort: Int?
    let peerPortRandomOnStart: Bool?
    let portIsOpen: Bool?

    enum CodingKeys: String, CodingKey {
        case version
        case downloadDir = "download-dir"
        case seedRatioLimit = "seedRatioLimit"
        case seedRatioLimited = "seedRatioLimited"
        case altSpeedEnabled = "alt-speed-enabled"
        case altSpeedTimeEnabled = "alt-speed-time-enabled"
        case altSpeedTimeBegin = "alt-speed-time-begin"
        case altSpeedTimeEnd = "alt-speed-time-end"
        case altSpeedTimeDay = "alt-speed-time-day"
        case speedLimitDown = "speed-limit-down"
        case speedLimitDownEnabled = "speed-limit-down-enabled"
        case speedLimitUp = "speed-limit-up"
        case speedLimitUpEnabled = "speed-limit-up-enabled"
        case encryption = "encryption"
        case peerLimitGlobal = "peer-limit-global"
        case peerLimitPerTorrent = "peer-limit-per-torrent"
        case blocklistEnabled = "blocklist-enabled"
        case blocklistURL = "blocklist-url"
        case blocklistSize = "blocklist-size"
        case peerPort = "peer-port"
        case peerPortRandomOnStart = "peer-port-random-on-start"
        case portIsOpen = "port-is-open"
    }
}

struct SessionSetArguments: Encodable {
    let speedLimitDown: Int
    let speedLimitDownEnabled: Bool
    let speedLimitUp: Int
    let speedLimitUpEnabled: Bool
    let altSpeedTimeEnabled: Bool
    let altSpeedTimeBegin: Int
    let altSpeedTimeEnd: Int
    let altSpeedTimeDay: Int

    enum CodingKeys: String, CodingKey {
        case speedLimitDown = "speed-limit-down"
        case speedLimitDownEnabled = "speed-limit-down-enabled"
        case speedLimitUp = "speed-limit-up"
        case speedLimitUpEnabled = "speed-limit-up-enabled"
        case altSpeedTimeEnabled = "alt-speed-time-enabled"
        case altSpeedTimeBegin = "alt-speed-time-begin"
        case altSpeedTimeEnd = "alt-speed-time-end"
        case altSpeedTimeDay = "alt-speed-time-day"
    }
}

struct SessionAltSpeedArguments: Encodable {
    let altSpeedEnabled: Bool

    enum CodingKeys: String, CodingKey {
        case altSpeedEnabled = "alt-speed-enabled"
    }
}

struct SessionSetPeerLimitsArguments: Encodable {
    let encryption: String
    let peerLimitGlobal: Int
    let peerLimitPerTorrent: Int

    enum CodingKeys: String, CodingKey {
        case encryption = "encryption"
        case peerLimitGlobal = "peer-limit-global"
        case peerLimitPerTorrent = "peer-limit-per-torrent"
    }
}

struct SessionSetBlocklistArguments: Encodable {
    let blocklistEnabled: Bool
    let blocklistURL: String

    enum CodingKeys: String, CodingKey {
        case blocklistEnabled = "blocklist-enabled"
        case blocklistURL = "blocklist-url"
    }
}

struct BlocklistUpdateResponseArguments: Decodable {
    let blocklistSize: Int
}

struct SessionSetPortArguments: Encodable {
    let peerPort: Int
    let peerPortRandomOnStart: Bool

    enum CodingKeys: String, CodingKey {
        case peerPort = "peer-port"
        case peerPortRandomOnStart = "peer-port-random-on-start"
    }
}

struct PortTestResponseArguments: Decodable {
    let portIsOpen: Bool

    enum CodingKeys: String, CodingKey {
        case portIsOpen = "port-is-open"
    }
}

struct FreeSpaceArguments: Encodable {
    let path: String
}

struct FreeSpaceResponseArguments: Decodable {
    let path: String
    let sizeBytes: Int

    enum CodingKeys: String, CodingKey {
        case path
        case sizeBytes = "size-bytes"
    }
}
