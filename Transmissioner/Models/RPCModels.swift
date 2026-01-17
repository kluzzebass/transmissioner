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

    enum CodingKeys: String, CodingKey {
        case version
        case downloadDir = "download-dir"
    }
}
