//
//  ProjectsService.swift
//  DIYGenieApp
//

import Foundation
import UIKit

// MARK: - ProjectsService
final class ProjectsService {
    private let baseURL = URL(string: "https://api.diygenieapp.com")!
    private let userId: String
    private let session: URLSession

    init(userId: String, session: URLSession = .shared) {
        self.userId = userId
        self.session = session
    }

    // MARK: - Create Project
    func createProject(name: String, goal: String, budget: String, skillLevel: String) async throws -> Project {
        let url = baseURL.appendingPathComponent("/api/projects")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let payload: [String: Any] = [
            "user_id": userId,
            "name": name,
            "goal": goal,
            "budget": budget,
            "skill_level": skillLevel
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }

        struct CreateResponse: Codable { let ok: Bool; let item: Project }
        let decoded = try JSONDecoder().decode(CreateResponse.self, from: data)
        return decoded.item
    }

    // MARK: - Upload Image
    func uploadImage(projectId: String, image: UIImage) async throws {
        guard let data = image.jpegData(compressionQuality: 0.8) else { return }

        let boundary = UUID().uuidString
        let url = baseURL.appendingPathComponent("/api/projects/\(projectId)/image")

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()
        let lineBreak = "\r\n"

        body.append("--\(boundary)\(lineBreak)")
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"photo.jpg\"\(lineBreak)")
        body.append("Content-Type: image/jpeg\(lineBreak + lineBreak)")
        body.append(data)
        body.append("\(lineBreak)--\(boundary)--\(lineBreak)")

        request.httpBody = body

        let (_, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
    }

    // MARK: - Generate Preview
    func generatePreview(projectId: String) async throws {
        let url = baseURL.appendingPathComponent("/api/projects/\(projectId)/preview")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = ["user_id": userId]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (_, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
    }

    // MARK: - Generate Plan Only (No Preview)
    func generatePlanOnly(projectId: String) async throws {
        let url = baseURL.appendingPathComponent("/api/projects/\(projectId)/plan")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = ["user_id": userId]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (_, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
    }

    // MARK: - Fetch All Projects
    func fetchProjects() async throws -> [Project] {
        var comps = URLComponents(url: baseURL.appendingPathComponent("/api/projects"), resolvingAgainstBaseURL: false)!
        comps.queryItems = [URLQueryItem(name: "user_id", value: userId)]
        guard let url = comps.url else { throw URLError(.badURL) }

        let (data, response) = try await session.data(from: url)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }

        struct ProjectsResponse: Codable { let ok: Bool; let items: [Project] }
        let decoded = try JSONDecoder().decode(ProjectsResponse.self, from: data)
        return decoded.items
    }

    // MARK: - Fetch Plan (for details view)
    func fetchPlan(projectId: String) async throws -> PlanResponse {
        let url = baseURL.appendingPathComponent("/api/projects/\(projectId)/plan")
        let (data, response) = try await session.data(from: url)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        return try JSONDecoder().decode(PlanResponse.self, from: data)
    }

    // MARK: - Upload AR Scan (legacy RoomPlan support)
    func uploadRoomScan(projectId: String, width: Double, height: Double, depth: Double) async throws {
        let url = baseURL.appendingPathComponent("/api/projects/\(projectId)/scan")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let payload: [String: Any] = [
            "roomplan": ["width": width, "height": height, "depth": depth, "objects": []]
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)

        let (_, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
    }

    // MARK: - Delete Project
    func deleteProject(projectId: String) async throws {
        let url = baseURL.appendingPathComponent("/api/projects/\(projectId)")
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        let (_, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
    }
}
