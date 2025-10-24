// ProjectsService.swift
// Networking layer for DIY Genie iOS app.

import Foundation

// MARK: - Models

/// A project as returned by the backend.
struct Project: Codable {
    let id: String
    let name: String
    let status: String
    let inputImageURL: URL?
    let previewURL: URL?

    enum CodingKeys: String, CodingKey {
        case id, name, status
        case inputImageURL = "input_image_url"
        case previewURL = "preview_url"
    }
}

/// Request body for creating a project.
struct CreateProjectRequest: Codable {
    struct Client: Codable {
        let budget: String?
    }
    let name: String
    let goal: String?
    let client: Client
}

/// Response for requesting a preview.
struct PreviewResponse: Codable {
    let id: String
    let state: String
    let updatedAt: String

    enum CodingKeys: String, CodingKey {
        case id, state
        case updatedAt = "updated_at"
    }
}

/// Full plan response (steps, tools, materials).
struct PlanResponse: Codable {
    let id: String
    let steps: [String]
    let tools: [String]
    let materials: [String]
    let updatedAt: String

    enum CodingKeys: String, CodingKey {
        case id, steps, tools, materials
        case updatedAt = "updated_at"
    }
}

/// Service errors.
enum ProjectsServiceError: Error {
    case invalidURL
    case invalidResponse
}

// MARK: - Service

final class ProjectsService {
    /// Base URL for the Express API (not the Supabase URL).
    static let baseURL = URL(string: "https://api.diygenieapp.com")!

    /// The authenticated user ID (UUID).
    private let userId: String

    init(userId: String) {
        self.userId = userId
    }

    /// Build a URL with the `user_id` query parameter.
    private func makeURL(path: String) -> URL {
        var components = URLComponents(url: Self.baseURL, resolvingAgainstBaseURL: false)!
        components.path = path
        components.queryItems = [URLQueryItem(name: "user_id", value: userId)]
        return components.url!
    }

    /// Fetch all projects for this user.
    func fetchProjects() async throws -> [Project] {
        let url = makeURL(path: "/api/projects")
        let (data, response) = try await URLSession.shared.data(from: url)
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw ProjectsServiceError.invalidResponse
        }
        // API returns {"items":[...]} so decode that wrapper
        struct Wrapper: Codable { let items: [Project] }
        let wrapper = try JSONDecoder().decode(Wrapper.self, from: data)
        return wrapper.items
    }

    /// Create a new project with a name, optional goal, and optional budget.
    func createProject(name: String, goal: String?, budget: String?) async throws -> Project {
        let url = makeURL(path: "/api/projects")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body = CreateProjectRequest(
            name: name,
            goal: goal,
            client: .init(budget: budget)
        )
        request.httpBody = try JSONEncoder().encode(body)
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw ProjectsServiceError.invalidResponse
        }
        return try JSONDecoder().decode(Project.self, from: data)
    }

    /// Upload a photo for a given project.
    func uploadPhoto(projectId: String, imageData: Data, fileName: String) async throws -> Project {
        let url = makeURL(path: "/api/projects/\(projectId)/photo")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        // Create multipart form body
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        var body = Data()

        // Append file data
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(fileName)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)

        request.httpBody = body
        let (data, response) = try await URLSession.shared.upload(for: request, from: body)
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw ProjectsServiceError.invalidResponse
        }
        return try JSONDecoder().decode(Project.self, from: data)
    }

    /// Request an AI preview for a project.
    func requestPreview(projectId: String) async throws -> PreviewResponse {
        let url = makeURL(path: "/api/projects/\(projectId)/preview")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw ProjectsServiceError.invalidResponse
        }
        return try JSONDecoder().decode(PreviewResponse.self, from: data)
    }

    /// Fetch the full plan for a project.
    func fetchPlan(projectId: String) async throws -> PlanResponse {
        let url = makeURL(path: "/api/projects/\(projectId)/plan")
        let (data, response) = try await URLSession.shared.data(from: url)
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw ProjectsServiceError.invalidResponse
        }
        return try JSONDecoder().decode(PlanResponse.self, from: data)
    }
}
