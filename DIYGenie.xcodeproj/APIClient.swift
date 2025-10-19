import Foundation

final class APIClient {
    typealias UserIDProvider = () -> String?

    static let shared = APIClient()

    private let baseURL: URL
    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder
    private let userIdProvider: UserIDProvider

    init(baseURL: URL = URL(string: AppConfig.baseURL)!,
         session: URLSession = .shared,
         userIdProvider: @escaping UserIDProvider = { nil }) {
        self.baseURL = baseURL
        self.session = session
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        self.decoder = decoder
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        self.encoder = encoder
        self.userIdProvider = userIdProvider
    }

    func makeURL(_ endpoint: String, query: [URLQueryItem] = []) throws -> URL {
        guard var comp = URLComponents(string: AppConfig.baseURL) else { throw APIError.invalidURL }
        comp.path = endpoint.hasPrefix("/") ? endpoint : "/\(endpoint)"
        if !query.isEmpty { comp.queryItems = query }
        guard let url = comp.url else { throw APIError.invalidURL }
        return url
    }

    func get<T: Decodable>(_ path: String, query: [URLQueryItem] = []) async throws -> T {
        let url = try makeURL(path, query: query)
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(UserSession.shared.userId, forHTTPHeaderField: "x-user-id")
        request.setValue(UserSession.shared.userId, forHTTPHeaderField: "X-User-Id")
        let (data, response) = try await session.data(for: request)
        try Self.validate(response: response, data: data)
        do { return try decoder.decode(T.self, from: data) } catch {
            let raw = String(data: data, encoding: .utf8) ?? "<non-utf8 body>"
            if let http = response as? HTTPURLResponse {
                print("[APIClient] Decode error for GET \(path) status: \(http.statusCode) body: \(raw) error: \(error)")
            } else {
                print("[APIClient] Decode error for GET \(path) body: \(raw) error: \(error)")
            }
            throw error
        }
    }

    func post<T: Decodable, Body: Encodable>(_ path: String, body: Body) async throws -> T {
        let url = try makeURL(path)
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(UserSession.shared.userId, forHTTPHeaderField: "x-user-id")
        request.setValue(UserSession.shared.userId, forHTTPHeaderField: "X-User-Id")
        request.httpBody = try encoder.encode(body)
        let (data, response) = try await session.data(for: request)
        try Self.validate(response: response, data: data)
        do { return try decoder.decode(T.self, from: data) } catch {
            let raw = String(data: data, encoding: .utf8) ?? "<non-utf8 body>"
            if let http = response as? HTTPURLResponse {
                print("[APIClient] Decode error for POST \(path) status: \(http.statusCode) body: \(raw) error: \(error)")
            } else {
                print("[APIClient] Decode error for POST \(path) body: \(raw) error: \(error)")
            }
            throw error
        }
    }

    func post<T: Decodable, Body: Encodable>(_ path: String, query: [URLQueryItem], body: Body) async throws -> T {
        let url = try makeURL(path, query: query)
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(UserSession.shared.userId, forHTTPHeaderField: "x-user-id")
        request.setValue(UserSession.shared.userId, forHTTPHeaderField: "X-User-Id")
        request.httpBody = try encoder.encode(body)
        let (data, response) = try await session.data(for: request)
        try Self.validate(response: response, data: data)
        do { return try decoder.decode(T.self, from: data) } catch {
            let raw = String(data: data, encoding: .utf8) ?? "<non-utf8 body>"
            if let http = response as? HTTPURLResponse {
                print("[APIClient] Decode error for POST \(path) status: \(http.statusCode) body: \(raw) error: \(error)")
            } else {
                print("[APIClient] Decode error for POST \(path) body: \(raw) error: \(error)")
            }
            throw error
        }
    }

    func delete<T: Decodable>(_ path: String) async throws -> T {
        let url = try makeURL(path)
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(UserSession.shared.userId, forHTTPHeaderField: "x-user-id")
        request.setValue(UserSession.shared.userId, forHTTPHeaderField: "X-User-Id")
        let (data, response) = try await session.data(for: request)
        try Self.validate(response: response, data: data)
        do { return try decoder.decode(T.self, from: data) } catch {
            let raw = String(data: data, encoding: .utf8) ?? "<non-utf8 body>"
            if let http = response as? HTTPURLResponse {
                print("[APIClient] Decode error for DELETE \(path) status: \(http.statusCode) body: \(raw) error: \(error)")
            } else {
                print("[APIClient] Decode error for DELETE \(path) body: \(raw) error: \(error)")
            }
            throw error
        }
    }

    private static func validate(response: URLResponse, data: Data) throws {
        guard let http = response as? HTTPURLResponse else { return }
        guard (200..<300).contains(http.statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? "<no body>"
            print("[APIClient] HTTP error status: \(http.statusCode) body: \(body)")
            throw APIError.httpError(status: http.statusCode, body: body)
        }
    }
}

enum APIError: Error, LocalizedError {
    case invalidURL
    case invalidRequest(String)
    case httpError(status: Int, body: String)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case let .invalidRequest(message):
            return "Invalid Request: \(message)"
        case let .httpError(status, body):
            return "HTTP \(status): \(body)"
        }
    }
}
