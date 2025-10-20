import Foundation

extension APIClient {
    static let shared = APIClient()

    /// Build a full URL by appending a path (with or without leading slash) and optional query items
    func makeURL(_ path: String, query: [URLQueryItem]? = nil) throws -> URL {
        var url = AppConfig.baseURL
        let trimmed = path.hasPrefix("/") ? String(path.dropFirst()) : path
        url.appendPathComponent(trimmed)
        if var comps = URLComponents(url: url, resolvingAgainstBaseURL: false) {
            if let query = query, !query.isEmpty {
                comps.queryItems = (comps.queryItems ?? []) + query
            }
            if let final = comps.url { return final }
        }
        return url
    }

    /// Perform a GET request and decode to T
    func get<T: Decodable>(_ path: String, query: [URLQueryItem]? = nil) async throws -> T {
        let url = try makeURL(path, query: query)
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        return try await perform(request)
    }

    /// Perform a POST with an Encodable body and decode to T
    func post<T: Decodable, B: Encodable>(_ path: String, query: [URLQueryItem]? = nil, body: B) async throws -> T {
        let url = try makeURL(path, query: query)
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(body)
        return try await perform(request)
    }

    /// Perform a DELETE and decode to T
    func delete<T: Decodable>(_ path: String, query: [URLQueryItem]? = nil) async throws -> T {
        let url = try makeURL(path, query: query)
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        return try await perform(request)
    }

    // MARK: - Internal request performer mirrors APIClient.request decoding behavior
    private func perform<T: Decodable>(_ request: URLRequest) async throws -> T {
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw APIError.unknown }
        guard (200..<300).contains(http.statusCode) else {
            let text = String(data: data, encoding: .utf8) ?? ""
            throw APIError.http(http.statusCode, text)
        }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            let text = String(data: data, encoding: .utf8) ?? ""
            throw APIError.decoding(text)
        }
    }
}
