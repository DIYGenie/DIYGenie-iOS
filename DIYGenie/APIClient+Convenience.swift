import Foundation

// Minimal error type so this file compiles if APIError isn't defined elsewhere.
// If your project already defines APIError, you can remove this and use that definition.
public enum APIError: Error {
    case network(underlying: String)
}

extension APIClient {
    // Singleton for call sites that expect it
    static let shared = APIClient(baseURL: AppConfig.baseURL)

    // Build a URL with query items
    func makeURL(_ path: String, query: [URLQueryItem]? = nil) throws -> URL {
        let base = baseURL.appendingPathComponent(path)
        guard var comps = URLComponents(url: base, resolvingAgainstBaseURL: false) else {
            throw APIError.network(underlying: "Invalid base URL")
        }
        if let query { comps.queryItems = query }
        guard let url = comps.url else {
            throw APIError.network(underlying: "Invalid URL for path \(path)")
        }
        return url
    }

    // Generic GET
    @discardableResult
    func get<T: Decodable>(_ path: String,
                           query: [URLQueryItem]? = nil) async throws -> T {
        // NOTE: request(path:method:query:body:) must be internal/public in APIClient (not private)
        return try await request(path: path, method: "GET", query: query, body: Optional<Data>.none as Data?)
    }

    // Generic POST (Encodable body)
    @discardableResult
    func post<T: Decodable, B: Encodable>(_ path: String,
                                          query: [URLQueryItem]? = nil,
                                          body: B) async throws -> T {
        return try await request(path: path, method: "POST", query: query, body: body)
    }

    // Generic DELETE
    @discardableResult
    func delete<T: Decodable>(_ path: String,
                              query: [URLQueryItem]? = nil) async throws -> T {
        return try await request(path: path, method: "DELETE", query: query, body: Optional<Data>.none as Data?)
    }
}
