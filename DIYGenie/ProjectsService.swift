// ProjectsService.swift
import Foundation

struct ProjectsService {
    private let api = APIClient.shared

    // MARK: - Models (internal helpers)
    private struct ListResponse: Decodable {
        let ok: Bool
        let items: [ProjectSummary]
    }

    private struct ProjectSummary: Decodable {
        let id: UUID
        let name: String
        let status: String?
        let inputImageURL: URL?
        let previewURL: URL?
        let goal: String?
    }

    private struct CreateRequest: Encodable {
        let name: String
        let goal: String?
        let client: Client?
        struct Client: Encodable { let budget: String? }
    }

    // MARK: - List
    func list(userId: String) async throws -> [Project] {
        let resp: ListResponse = try await api.get(
            "/api/projects",
            query: [URLQueryItem(name: "user_id", value: userId)]
        )
        // Map to lightweight Project used by UI
        return resp.items.map {
            Project(id: $0.id.uuidString, name: $0.name, goal: $0.goal, status: $0.status ?? "draft")
        }
    }

    // MARK: - Create
    /// Creates a project and returns the lightweight `Project` for UI.
    func create(userId: String, name: String, goal: String?, budget: String?) async throws -> Project {
        let body = CreateRequest(
            name: name,
            goal: goal,
            client: .init(budget: budget)
        )
        let dto: ProjectSummary = try await api.post(
            "/api/projects",
            query: [URLQueryItem(name: "user_id", value: userId)],
            body: body
        )
        return Project(id: dto.id.uuidString, name: dto.name, goal: dto.goal, status: dto.status ?? "draft")
    }

    // MARK: - Upload Photo (multipart JPEG)
    func uploadPhoto(userId: String, projectId: String, jpegData: Data) async throws -> BoolResponse {
        // Build multipart manually
        let boundary = "Boundary-\(UUID().uuidString)"
        var url = api.baseURL.appendingPathComponent("/api/projects/\(projectId)/photo")
        if var comps = URLComponents(url: url, resolvingAgainstBaseURL: false) {
            comps.queryItems = [URLQueryItem(name: "user_id", value: userId)]
            url = comps.url ?? url
        }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()
        let crlf = "\r\n"
        body.append("--\(boundary)\(crlf)".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"photo.jpg\"\(crlf)".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\(crlf + crlf)".data(using: .utf8)!)
        body.append(jpegData)
        body.append("\(crlf)--\(boundary)--\(crlf)".data(using: .utf8)!)
        req.httpBody = body

        let (data, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse else { throw URLError(.badServerResponse) }
        guard (200..<300).contains(http.statusCode) else { throw UploadHTTPError.badStatus(code: http.statusCode, data: data) }

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601
        if let ok = try? decoder.decode(BoolResponse.self, from: data) { return ok }
        return BoolResponse(ok: true) // tolerate empty body
    }

    // MARK: - Queue Preview
    func preview(userId: String, projectId: String) async throws -> PreviewStatus {
        struct Empty: Encodable {}
        return try await api.post(
            "/api/projects/\(projectId)/preview",
            query: [URLQueryItem(name: "user_id", value: userId)],
            body: Empty()
        )
    }

    // MARK: - Fetch Plan
    func plan(userId: String, projectId: String) async throws -> Plan {
        try await api.get(
            "/api/projects/\(projectId)/plan",
            query: [URLQueryItem(name: "user_id", value: userId)]
        )
    }
}

private enum UploadHTTPError: Error, LocalizedError {
    case badStatus(code: Int, data: Data)

    var errorDescription: String? {
        switch self {
        case let .badStatus(code, data):
            let snippet = String(data: data, encoding: .utf8) ?? "<no body>"
            return "Upload failed with HTTP status \(code): \(snippet)"
        }
    }
}

// ✅ Ready to Build
