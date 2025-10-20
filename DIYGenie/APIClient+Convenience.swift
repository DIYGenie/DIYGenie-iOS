import Foundation

extension APIClient {
    // Singleton for call sites that expect it
    static let shared = APIClient(baseURL: AppConfig.baseURL)

    // Build a URL with query items
    func makeURL(_ path: String, query: [URLQueryItem]? = nil) throws -> URL {
        guard var comps = URLComponents(url: baseURL.appendingPathComponent(path), resolvingAgainstBaseURL: false) else {
            throw APIError.network("Invalid base URL")
        }
        if let query { comps.queryItems = query }
        guard let url = comps.url else { throw APIError.network("Invalid URL for path \(path)") }
        return url
    }

    // Generic GET
    @discardableResult
    func get<T: Decodable>(_ path: String,
                           query: [URLQueryItem]? = nil) async throws -> T {
        // NOTE: request(path:method:body:) must be internal/public in APIClient (not private)
        return try await request(path: path, method: "GET", body: Optional<Data>.none as Data?)
    }

    // Generic POST (Encodable body)
    @discardableResult
    func post<T: Decodable, B: Encodable>(_ path: String,
                                          query: [URLQueryItem]? = nil,
                                          body: B) async throws -> T {
        return try await request(path: path, method: "POST", body: body)
    }

    // Generic DELETE
    @discardableResult
    func delete<T: Decodable>(_ path: String,
                              query: [URLQueryItem]? = nil) async throws -> T {
        return try await request(path: path, method: "DELETE", body: Optional<Data>.none as Data?)
    }
}
