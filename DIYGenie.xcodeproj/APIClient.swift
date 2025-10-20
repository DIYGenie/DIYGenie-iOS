import Foundation

/// Central, lightweight HTTP client for DIY Genie.
public final class APIClient {

    // MARK: - Properties
    public let baseURL: URL

    // Single shared instance for app-wide use
    public static let shared = APIClient(baseURL: AppConfig.baseURL)

    // MARK: - Init
    public init(baseURL: URL) {
        self.baseURL = baseURL
    }

    // MARK: - Public convenience

    /// Health ping: GET /api/ios/health
    func health() async throws -> HealthDTO {
        try await get("/api/ios/health")
    }

    // Generic GET
    @discardableResult
    public func get<T: Decodable>(
        _ path: String,
        query: [URLQueryItem]? = nil
    ) async throws -> T {
        try await request(path: path, method: "GET", query: query, body: Optional<Data>.none)
    }

    // Generic POST (Encodable body)
    @discardableResult
    public func post<T: Decodable, B: Encodable>(
        _ path: String,
        query: [URLQueryItem]? = nil,
        body: B
    ) async throws -> T {
        let data = try JSONEncoder().encode(body)
        return try await request(path: path, method: "POST", query: query, body: data)
    }

    // Generic DELETE
    @discardableResult
    public func delete<T: Decodable>(
        _ path: String,
        query: [URLQueryItem]? = nil
    ) async throws -> T {
        try await request(path: path, method: "DELETE", query: query, body: Optional<Data>.none)
    }

    // MARK: - Core request

    private func request<T: Decodable>(
        path: String,
        method: String,
        query: [URLQueryItem]? = nil,
        body: Data?
    ) async throws -> T {

        // Build URL with query
        guard var comps = URLComponents(url: baseURL.appendingPathComponent(path), resolvingAgainstBaseURL: false) else {
            throw APIError.invalidRequest("Invalid base URL")
        }
        if let query { comps.queryItems = query }
        guard let url = comps.url else {
            throw APIError.invalidRequest("Invalid URL for path \(path)")
        }

        // Build request
        var req = URLRequest(url: url)
        req.httpMethod = method
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Optional: inject x-user-id if you keep one in memory
        let uid = UserSession.shared.userId
        if !uid.isEmpty {
            req.setValue(uid, forHTTPHeaderField: "X-User-Id")
        }

        if let body = body {
            req.httpBody = body
        }

        // Send
        let (data, resp) = try await URLSession.shared.data(for: req)

        guard let http = resp as? HTTPURLResponse else {
            throw APIError.network(underlying: "Invalid response type")
        }

        // 2xx → decode
        if (200..<300).contains(http.statusCode) {
            let dec = Self.makeDecoder()
            do {
                #if DEBUG
                // Helpful when T == String/Bool, we still decode as JSON
                #endif
                return try dec.decode(T.self, from: data)
            } catch {
                let raw = String(data: data, encoding: .utf8) ?? "<non-utf8>"
                #if DEBUG
                print("DECODING ERROR for \(path): \(error)\nRAW: \(raw)")
                #endif
                throw APIError.decoding(underlying: error.localizedDescription)
            }
        }

        // Non-2xx → throw APIError.httpError
        let text = String(data: data, encoding: .utf8) ?? "<no body>"
        #if DEBUG
        print("HTTP \(http.statusCode) \(path)\nRAW: \(text)")
        #endif
        throw APIError.httpError(status: http.statusCode, responseBody: text)
    }

    // MARK: - Helpers

    private static func makeDecoder() -> JSONDecoder {
        let dec = JSONDecoder()
        dec.keyDecodingStrategy = .convertFromSnakeCase
        // ISO 8601 with/without fractional seconds
        let fmt = ISO8601DateFormatter()
        fmt.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        dec.dateDecodingStrategy = .custom { decoder in
            let c = try decoder.singleValueContainer()
            let s = try c.decode(String.self)
            if let d = fmt.date(from: s) { return d }
            // Fallback without fractional seconds
            let fallback = ISO8601DateFormatter()
            fallback.formatOptions = [.withInternetDateTime]
            if let d = fallback.date(from: s) { return d }
            throw DecodingError.dataCorruptedError(in: c, debugDescription: "Bad ISO8601 date: \(s)")
        }
        return dec
    }
}

