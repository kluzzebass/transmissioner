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
    let filesWanted: [Int]
    let filesUnwanted: [Int]
    let priorityHigh: [Int]
    let priorityNormal: [Int]
    let priorityLow: [Int]

    enum CodingKeys: String, CodingKey {
        case ids
        case filesWanted = "files-wanted"
        case filesUnwanted = "files-unwanted"
        case priorityHigh = "priority-high"
        case priorityNormal = "priority-normal"
        case priorityLow = "priority-low"
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

struct TorrentAddArguments: Encodable {
    let filename: String
    let downloadDir: String?

    enum CodingKeys: String, CodingKey {
        case filename
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
