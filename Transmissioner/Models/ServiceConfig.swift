import Foundation

struct ServiceConfig: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var baseURL: URL
    var rpcPath: String
    var username: String
    var password: String

    init(
        id: UUID = UUID(),
        name: String,
        baseURL: URL,
        rpcPath: String = "transmission/rpc",
        username: String = "",
        password: String = ""
    ) {
        self.id = id
        self.name = name
        self.baseURL = baseURL
        self.rpcPath = rpcPath
        self.username = username
        self.password = password
    }

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case baseURL
        case rpcPath
        case username
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        baseURL = try container.decode(URL.self, forKey: .baseURL)
        rpcPath = try container.decodeIfPresent(String.self, forKey: .rpcPath) ?? "transmission/rpc"
        username = try container.decodeIfPresent(String.self, forKey: .username) ?? ""
        password = ""
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(baseURL, forKey: .baseURL)
        try container.encode(rpcPath, forKey: .rpcPath)
        try container.encode(username, forKey: .username)
    }

    var rpcURL: URL {
        let trimmedPath = rpcPath.hasPrefix("/") ? String(rpcPath.dropFirst()) : rpcPath
        return baseURL.appendingPathComponent(trimmedPath)
    }
}
