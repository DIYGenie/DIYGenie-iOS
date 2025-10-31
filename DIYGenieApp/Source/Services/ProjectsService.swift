//
//  ProjectsService.swift
//  DIYGenieApp
//

import Foundation
import Supabase
import UIKit

struct ProjectsService {
    private let userId: String
    private let client = SupabaseConfig.client

    init(userId: String) {
        self.userId = userId
    }

    // MARK: - Fetch All Projects
    func fetchProjects() async throws -> [Project] {
        let response = try await client
            .from("projects")
            .select()
            .eq("user_id", value: userId)
            .order("created_at", ascending: false)
            .execute()

        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw NSError(domain: "ProjectsService", code: 2, userInfo: [NSLocalizedDescriptionKey: "Invalid image data"])
        }

        }

    if let imageData = image.jpegData(compressionQuality: 0.8) { ... }
        return try JSONDecoder().decode([Project].self, from: jsonData)
    }

    // MARK: - Create New Project
    func createProject(
        name: String,
        goal: String,
        budget: String,
        skillLevel: String
    ) async throws -> Project {

        let insert: [String: AnyEncodable] = [
            "user_id": AnyEncodable(userId),
            "name": AnyEncodable(name),
            "goal": AnyEncodable(goal),
            "budget": AnyEncodable(budget),
            "skill_level": AnyEncodable(skillLevel)
        ]

        let response = try await client
            .from("projects")
            .insert(values: insert)
            .select()
            .single()
            .execute()

        guard let data = response.data else {
            throw NSError(domain: "ProjectsService", code: 1,
                          userInfo: [NSLocalizedDescriptionKey: "Failed to create project"])
        }

        let jsonData = try JSONSerialization.data(withJSONObject: data)
        return try JSONDecoder().decode(Project.self, from: jsonData)
    }

    // MARK: - Upload Image to Supabase Storage
    func uploadImage(projectId: String, image: UIImage) async throws {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw NSError(domain: "ProjectsService", code: 2,
                          userInfo: [NSLocalizedDescriptionKey: "Invalid image data"])
        }

        let path = "\(userId)/\(UUID().uuidString).jpg"
        let bucket = client.storage.from("uploads")

        // ✅ Upload file
        _ = try await bucket.upload(path, data: imageData,
                                    options: FileOptions(contentType: "image/jpeg"))

        // ✅ Retrieve public URL
        let publicURL = try await bucket.getPublicURL(path: path)
        print("🟢 Uploaded image URL:", publicURL)

        // ✅ Save URL in project record
        _ = try await client
            .from("projects")
            .update(value: ["input_image_url": AnyEncodable(publicURL.absoluteString)])
            .eq("id", value: projectId)
            .execute()

        print("🟣 Updated project \(projectId) with image URL")
    }

    // MARK: - Generate Plan Only
    func generatePlanOnly(projectId: String) async throws -> PlanResponse {
        let url = URL(string: "\(Constants.apiBase)/generate-plan/\(projectId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        let (data, _) = try await URLSession.shared.data(for: request)
        return try JSONDecoder().decode(PlanResponse.self, from: data)
    }

    // MARK: - Generate Decor8 Preview
    func generatePreview(projectId: String) async throws -> String {
        let url = URL(string: "\(Constants.apiBase)/generate-preview/\(projectId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode([String: String].self, from: data)
        guard let previewURL = response["preview_url"] else {
            throw NSError(domain: "ProjectsService", code: 4,
                          userInfo: [NSLocalizedDescriptionKey: "Missing preview_url in response"])
        }

        print("🟩 Generated Decor8 preview:", previewURL)
        return previewURL
    }
}

