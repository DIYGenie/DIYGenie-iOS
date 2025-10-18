import Foundation

struct ProjectsService {
    private let api = APIClient.shared

    func fetchProjects() async throws -> [Project] {
        try await api.get("/api/projects")
    }

    func deleteProject(id: String) async throws -> BoolResponse {
        try await api.delete("/api/projects/\(id)")
    }
}

struct BoolResponse: Codable { let success: Bool }
