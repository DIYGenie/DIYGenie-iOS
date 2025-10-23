import Foundation

struct Project: Codable {
    let id: String
    let name: String
    let status: String
    let inputImageURL: URL?
    let previewURL: URL?
}

struct CreateProjectRequest: Codable {
    let name: String
    let goal: String?
    let client: Client
    struct Client: Codable {
        let budget: String?
    }
}

struct PlanResponse: Codable {
    let id: String
    let tools: [String]?
    let materials: [String]?
    let steps: [String]?
    let updated_at: String?
}

enum ProjectsServiceError: Error {
    case invalidURL
    case invalidResponse
}

class ProjectsService {
    static let baseURL = URL(string: "https://api.diygenieapp.com")!

    let userId: String

    init(userId: String) {
        self.userId = userId
    }

    private func makeURL(path: String) -> URL {
        var components = URLComponents(url: ProjectsService.baseURL, resolvingAgainstBaseURL: false)!
        components.path = path
        components.queryItems = [URLQueryItem(name: "user_id", value: userId)]
        return components.url!
    }

    func fetchProjects() async throws -> [Project] {
        let url = makeURL(path: "/api/projects")
        let (data, response) = try await URLSession.shared.data(from: url)
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw ProjectsServiceError.invalidResponse
        }
        return try JSONDecoder().decode([Project].self, from: data)
    }

    func createProject(name: String, goal: String?, budget: String?) async throws -> Project {
        var components = URLComponents(url: ProjectsService.baseURL.appendingPathComponent("/api/projects"), resolvingAgainstBaseURL: false)!
        components.queryItems = [URLQueryItem(name: "user_id", value: userId)]
        guard let url = components.url else { throw ProjectsServiceError.invalidURL }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let requestBody = CreateProjectRequest(name: name, goal: goal, client: .init(budget: budget))
        request.httpBody = try JSONEncoder().encode(requestBody)
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw ProjectsServiceError.invalidResponse
        }
        return try JSONDecoder().decode(Project.self, from: data)
    }

    func uploadPhoto(projectId: String, imageData: Data, filename: String, note: String?) async throws -> Project {
        let path = "/api/projects/\(projectId)/photo"
        var components = URLComponents(url: ProjectsService.baseURL.appendingPathComponent(path), resolvingAgainstBaseURL: false)!
        components.queryItems = [URLQueryItem(name: "user_id", value: userId)]
        guard let url = components.url else { throw ProjectsServiceError.invalidURL }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n".data(using: .utf8)!)
        if let note = note {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"note\"\r\n\r\n".data(using: .utf8)!)
            body.append(note.data(using: .utf8)!)
            body.append("\r\n".data(using: .utf8)!)
        }
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = body
        let (data, response) = try await URLSession.shared.upload(for: request, from: body)
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw ProjectsServiceError.invalidResponse
        }
        return try JSONDecoder().decode(Project.self, from: data)
    }

    func requestPreview(projectId: String) async throws -> Project {
        var components = URLComponents(url: ProjectsService.baseURL.appendingPathComponent("/api/projects/\(projectId)/preview"), resolvingAgainstBaseURL: false)!
        components.queryItems = [URLQueryItem(name: "user_id", value: userId)]
        guard let url = components.url else { throw ProjectsServiceError.invalidURL }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw ProjectsServiceError.invalidResponse
        }
        return try JSONDecoder().decode(Project.self, from: data)
    }

    func fetchPlan(projectId: String) async throws -> PlanResponse {
        var components = URLComponents(url: ProjectsService.baseURL.appendingPathComponent("/api/projects/\(projectId)/plan"), resolvingAgainstBaseURL: false)!
        components.queryItems = [URLQueryItem(name: "user_id", value: userId)]
        guard let url = components.url else { throw ProjectsServiceError.invalidURL }
        let (data, response) = try await URLSession.shared.data(from: url)
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw ProjectsServiceError.invalidResponse
        }
        return try JSONDecoder().decode(PlanResponse.self, from: data)
    }
}
