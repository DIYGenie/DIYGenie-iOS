import Foundation

/// High-level app API for Projects.
/// Uses APIClient.shared and DTOs.swift shapes.
struct ProjectsService {
    static let shared = ProjectsService()
    private let api = APIClient.shared

    // MARK: - Create Project
    func create(
        name: String,
        goal: String,
        budget: Double,
        skill: String,
        userId: String
    ) async throws -> Project {
        guard let uid = UUID(uuidString: userId) else {
            throw APIError.invalidRequest("Bad userId: \(userId)")
        }

        let body = CreateProjectBody(
            name: name,
            goal: goal,
            user_id: uid,
            client: "ios",
            budget: budget,
            skill_level: skill
        )

        let dto: CreateProjectDTO = try await api.post(
            "/api/projects",
            query: [URLQueryItem(name: "user_id", value: userId)],
            body: body
        )

        // Map DTO → lightweight Project model used by the UI
        return Project(
            id: dto.id.uuidString,
            name: dto.name,
            goal: dto.goal,
            status: "created"
        )
    }

    // MARK: - List Projects
    func list(userId: String) async throws -> [Project] {
        struct ListResponse: Decodable { let ok: Bool; let items: [Project] }
        let resp: ListResponse = try await api.get(
            "/api/projects",
            query: [URLQueryItem(name: "user_id", value: userId)]
        )
        return resp.items
    }

    // MARK: - Attach Photo
    func attachPhoto(projectId: UUID, url: URL) async throws -> Bool {
        struct PhotoBody: Encodable { let url: URL }
        let resp: BoolResponse = try await api.post(
            "/api/projects/\(projectId.uuidString)/photo",
            body: PhotoBody(url: url)
        )
        return resp.ok
    }

    // MARK: - Request Preview
    func requestPreview(projectId: UUID) async throws -> PreviewStatus {
        struct Empty: Encodable {}
        return try await api.post(
            "/api/projects/\(projectId.uuidString)/preview",
            body: Empty()
        )
    }

    // MARK: - Fetch Plan
    func fetchPlan(projectId: UUID) async throws -> Plan {
        try await api.get("/api/projects/\(projectId.uuidString)/plan")
    }
}
