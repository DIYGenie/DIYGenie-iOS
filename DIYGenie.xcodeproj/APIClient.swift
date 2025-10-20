import Foundation

extension JSONDecoder {
    static var apiDecoder: JSONDecoder {
        let d = JSONDecoder()
        d.keyDecodingStrategy = .convertFromSnakeCase
        d.dateDecodingStrategy = .iso8601
        return d
    }
}

final class APIClient {
    static let shared = APIClient()
    
    let baseURL: URL
    private let session: URLSession

    init(baseURL: URL = AppConfig.baseURL, session: URLSession = .shared) {
        self.baseURL = baseURL
        self.session = session
    }

    // Generic request
    func request<T: Decodable>(path: String, method: String = "GET", body: (any Encodable)? = nil) async throws -> T {
        var url = baseURL.appendingPathComponent(path)
        // Normalize leading slash handling
        if path.hasPrefix("/") {
            url = baseURL.appendingPathComponent(String(path.dropFirst()))
        }
        var request = URLRequest(url: url)
        request.httpMethod = method
        if let body = body {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONEncoder().encode(AnyEncodable(body))
        }

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw APIError.unknown(message: nil) }
        guard (200..<300).contains(http.statusCode) else {
            let text = String(data: data, encoding: .utf8) ?? ""
            throw APIError.network(underlying: "HTTP \(http.statusCode)")
        }
        let decoder = JSONDecoder.apiDecoder
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            let text = String(data: data, encoding: .utf8) ?? ""
            throw APIError.network(underlying: "Decoding failed: \(text)")
        }
    }

    // MARK: - DTOs
    private struct HealthDTO: Decodable {
        let ok: Bool
        let ts: Date
        let version: String
    }

    private struct CreateProjectBody: Encodable {
        let name: String
        let goal: String
        let user_id: UUID
        let client: String
        let budget: Double
        let skill_level: String
    }

    private struct PhotoBody: Encodable { let url: URL }
    private struct PhotoResponse: Decodable { let ok: Bool; let photo_url: URL }
    private struct PreviewResponse: Decodable { let status: String; let preview_id: String? }

    // MARK: - Public API
    func health() async throws -> (ok: Bool, ts: Date, version: String) {
        let dto: HealthDTO = try await request(path: "/api/ios/health")
        return (ok: dto.ok, ts: dto.ts, version: dto.version)
    }

    func createProject(name: String, goal: String, userId: UUID, budget: Double, skillLevel: String) async throws -> Project {
        let body = CreateProjectBody(name: name, goal: goal, user_id: userId, client: "ios", budget: budget, skill_level: skillLevel)
        let dto: CreateProjectDTO = try await request(path: "/api/projects", method: "POST", body: body)
        return Project(dto)
    }

    func attachPhoto(projectId: UUID, url: URL) async throws -> (ok: Bool, photo_url: URL) {
        let body = PhotoBody(url: url)
        let resp: PhotoResponse = try await request(path: "/api/projects/\(projectId.uuidString)/photo", method: "POST", body: body)
        return (ok: resp.ok, photo_url: resp.photo_url)
    }

    func requestPreview(projectId: UUID) async throws -> PreviewStatus {
        struct Empty: Encodable {}
        let status: PreviewStatus = try await request(path: "/api/projects/\(projectId.uuidString)/preview", method: "POST", body: Empty())
        return status
    }

    func fetchPlan(projectId: UUID) async throws -> Plan {
        let plan: Plan = try await request(path: "/api/projects/\(projectId.uuidString)/plan")
        return plan
    }
}

// Helper to encode `Encodable` existential
private struct AnyEncodable: Encodable {
    private let _encode: (Encoder) throws -> Void
    init(_ wrapped: Encodable) {
        self._encode = wrapped.encode
    }
    func encode(to encoder: Encoder) throws { try _encode(encoder) }
}
