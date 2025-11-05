//
//  ProjectsService.swift
//  DIYGenieApp
//

import Foundation
import UIKit
import Supabase

struct ProjectsService {

    // MARK: - Dependencies
    let userId: String
    let client: SupabaseClient

    init(userId: String,
         client: SupabaseClient = SupabaseConfig.client) {
        self.userId = userId
        self.client = client
    }

    // MARK: - Create Project
    @discardableResult
    func createProject(
        name: String,
        goal: String?,
        budget: String?,
        skillLevel: String?
    ) async throws -> Project {
        var payload: [String: AnyEncodable] = [
            "user_id": AnyEncodable(userId),
            "name": AnyEncodable(name)
        ]
        if let goal { payload["goal"] = AnyEncodable(goal) }
        if let budget { payload["budget"] = AnyEncodable(budget) }
        if let skillLevel { payload["skill_level"] = AnyEncodable(skillLevel) }

        // Insert and return the created row
        let response: PostgrestResponse<Project> = try await client
            .from("projects")
            .insert(payload)
            .select()
            .single()
            .execute()

        return response.value
    }

    // MARK: - Upload Photo → Storage → update input_image_url
    func uploadImage(projectId: String, image: UIImage) async throws {
        guard let data = image.jpegData(compressionQuality: 0.9) else {
            throw NSError(domain: "ProjectsService", code: -10,
                          userInfo: [NSLocalizedDescriptionKey: "Invalid image data"])
        }

        // Storage path: <userId>/<uuid>.jpg
        let path = "\(userId)/\(UUID().uuidString).jpg"
        let options = FileOptions(contentType: "image/jpeg")

        let bucket = client.storage.from("uploads")
        _ = try await bucket.upload(path: path, file: data, options: options)

        // Build public URL for display
        let publicURL = SupabaseConfig.publicURL(bucket: "uploads", path: path).absoluteString

        let update: [String: AnyEncodable] = ["input_image_url": AnyEncodable(publicURL)]

        _ = try await client
            .from("projects")
            .update(update)
            .eq("id", value: projectId)
            .execute()
    }

    // MARK: - Trigger server preview -> returns preview URL string
    func generatePreview(projectId: String) async throws -> String {
        let base = API.baseURL
        let url = try requireURL_(base: base)
            .appendingPathComponent("api")
            .appendingPathComponent("projects")
            .appendingPathComponent(projectId)
            .appendingPathComponent("generate-preview")

        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let (data, response) = try await URLSession.shared.data(for: req)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw NSError(domain: "ProjectsService",
                          code: (response as? HTTPURLResponse)?.statusCode ?? -1,
                          userInfo: [NSLocalizedDescriptionKey: "Preview failed: \(body)"])
        }

        let obj = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let urlString = obj?["preview_url"] as? String else {
            throw NSError(domain: "ProjectsService", code: -11,
                          userInfo: [NSLocalizedDescriptionKey: "preview_url missing"])
        }
        return urlString
    }

    // MARK: - Plan (server) → full JSON
    func generatePlanOnly(projectId: String) async throws -> PlanResponse {
        let base = API.baseURL
        let url = try requireURL_(base: base)
            .appendingPathComponent("api")
            .appendingPathComponent("projects")
            .appendingPathComponent(projectId)
            .appendingPathComponent("generate-plan")

        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let (data, response) = try await URLSession.shared.data(for: req)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw NSError(domain: "ProjectsService",
                          code: (response as? HTTPURLResponse)?.statusCode ?? -1,
                          userInfo: [NSLocalizedDescriptionKey: "Plan failed: \(body)"])
        }

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(PlanResponse.self, from: data)
    }

    // MARK: - Fetch projects for current user
    func fetchProjects() async throws -> [Project] {
        let response: PostgrestResponse<[Project]> = try await client
            .from("projects")
            .select()
            .eq("user_id", value: userId)
            .order("created_at", ascending: false)
            .execute()

        return response.value
    }

    // MARK: - Helpers
    private func requireURL_(base: String) throws -> URL {
        guard let url = URL(string: base) else {
            throw NSError(domain: "ProjectsService",
                          code: -99,
                          userInfo: [NSLocalizedDescriptionKey: "Invalid API_BASE_URL"])
        }
        return url
    }
}

