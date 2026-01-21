import Foundation

enum TransmissionRPCError: Error, LocalizedError {
    case invalidResponse
    case httpError(Int)
    case missingSessionID
    case rpcError(String)
    case invalidURL

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid response from Transmission."
        case .httpError(let status):
            return "Transmission returned HTTP \(status)."
        case .missingSessionID:
            return "Missing Transmission session id."
        case .rpcError(let message):
            return "Transmission error: \(message)"
        case .invalidURL:
            return "Service URL is invalid."
        }
    }
}

final class TransmissionRPCClient {
    private let config: ServiceConfig
    private var sessionID: String?
    private let urlSession: URLSession

    init(config: ServiceConfig, allowInsecureTLS: Bool = false, urlSession: URLSession? = nil) {
        self.config = config
        if let urlSession {
            self.urlSession = urlSession
        } else if allowInsecureTLS {
            self.urlSession = URLSession(
                configuration: .default,
                delegate: InsecureTLSDelegate(),
                delegateQueue: nil
            )
        } else {
            self.urlSession = .shared
        }
    }

    func request<Arguments: Encodable, ResponseArguments: Decodable>(
        method: String,
        arguments: Arguments? = nil
    ) async throws -> ResponseArguments {
        var request = try buildRequest(method: method, arguments: arguments)
        var (data, response) = try await urlSession.data(for: request)

        if let http = response as? HTTPURLResponse, http.statusCode == 409 {
            guard let newSessionID = http.value(forHTTPHeaderField: "X-Transmission-Session-Id") else {
                throw TransmissionRPCError.missingSessionID
            }
            sessionID = newSessionID
            request = try buildRequest(method: method, arguments: arguments)
            (data, response) = try await urlSession.data(for: request)
        }

        guard let http = response as? HTTPURLResponse else {
            throw TransmissionRPCError.invalidResponse
        }
        guard (200..<300).contains(http.statusCode) else {
            throw TransmissionRPCError.httpError(http.statusCode)
        }

        let decoded = try JSONDecoder().decode(RPCResponse<ResponseArguments>.self, from: data)
        guard decoded.result == "success" else {
            throw TransmissionRPCError.rpcError(decoded.result)
        }

        if let arguments = decoded.arguments {
            return arguments
        }

        if ResponseArguments.self == EmptyResponse.self, let empty = EmptyResponse() as? ResponseArguments {
            return empty
        }

        throw TransmissionRPCError.invalidResponse
    }

    private func buildRequest<Arguments: Encodable>(
        method: String,
        arguments: Arguments?
    ) throws -> URLRequest {
        let url = config.rpcURL
        guard let scheme = url.scheme, !scheme.isEmpty else {
            throw TransmissionRPCError.invalidURL
        }

        let body = RPCRequest(method: method, arguments: arguments, tag: nil)
        let encoded = try JSONEncoder().encode(body)

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = encoded
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let sessionID {
            request.setValue(sessionID, forHTTPHeaderField: "X-Transmission-Session-Id")
        }

        if !config.username.isEmpty {
            let authString = "\(config.username):\(config.password)"
            if let authData = authString.data(using: .utf8) {
                let encodedAuth = authData.base64EncodedString()
                request.setValue("Basic \(encodedAuth)", forHTTPHeaderField: "Authorization")
            }
        }

        return request
    }
}

private final class InsecureTLSDelegate: NSObject, URLSessionDelegate {
    func urlSession(
        _ session: URLSession,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        guard challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
              let trust = challenge.protectionSpace.serverTrust else {
            completionHandler(.performDefaultHandling, nil)
            return
        }
        completionHandler(.useCredential, URLCredential(trust: trust))
    }
}
