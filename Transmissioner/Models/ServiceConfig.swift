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

    var rpcURL: URL {
        let trimmedPath = rpcPath.hasPrefix("/") ? String(rpcPath.dropFirst()) : rpcPath
        return baseURL.appendingPathComponent(trimmedPath)
    }
}
