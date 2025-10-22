// ProjectsService.swift
import Foundation

// ProjectsService.swift
struct ProjectsService {
    private let api = APIClient(baseURL: URL(string: "https://api.diygenieapp.com")!)
    // ...
    // MARK: - Create Project
    func create(userId: String, body: CreateProjectBody) async throws -> CreateProjectDTO {
        try await api.post(
            "/api/projects",
            query: [URLQueryItem(name: "user_id", value: userId)],
            body: body
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

    // MARK: - Upload Photo (multipart already working)
    func uploadPhoto(userId: String, projectId: String, jpegData: Data) async throws {
        // your existing multipart uploader here (unchanged)
    }

    // MARK: - Preview
    func preview(userId: String, projectId: String) async throws {
        // your existing preview call here (unchanged)
    }

    // MARK: - Plan
    func plan(userId: String, projectId: String) async throws {
        // your existing plan call (unchanged or return a DTO if you prefer)
    }
}
