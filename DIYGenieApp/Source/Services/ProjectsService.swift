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

    // MARK: - Init
    init(userId: String? = nil) {
        if let id = userId ?? UserDefaults.standard.string(forKey: "user_id") {
            self.userId = id
        } else {
            let newId = UUID().uuidString
            UserDefaults.standard.set(newId, forKey: "user_id")
            self.userId = newId
        }
    }

    // MARK: - Fetch All Projects
    func fetchProjects() async throws -> [Project] {
        let response = try await client
            .from("projects")
            .select()
            .eq("user_id", value: userId)
            .order("created_at", ascending: false)
            .execute()

        let data = response.data
        let jsonData = try JSONSerialization.data(withJSONObject: data)
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
            "skill_level": AnyEncodable(skillLevel),
            "status": AnyEncodable("draft")
        ]

        let response = try await client
            .from("projects")
            .insert(insert)
            .select()
            .single()
            .execute()

        let data = response.data
        let jsonData = try JSONSerialization.data(withJSONObject: data)
        return try JSONDecoder().decode(Project.self, from: jsonData)
    }

    // MARK: - Upload Image to Supabase Storage
    func uploadImage(projectId: String, image: UIImage) async throws {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw NSError(
                domain: "ProjectsService",
                code: 102,
                userInfo: [NSLocalizedDescriptionKey: "Invalid image data."]
            )
        }

        let path = "\(userId)/\(UUID().uuidString).jpg"
        let bucket = client.storage.from("uploads")

        // Upload
        _ = try await bucket.upload(
            path,
            data: imageData,
            options: FileOptions(contentType: "image/jpeg", upsert: false)
        )

        // Public URL
        let publicURL = try bucket.getPublicURL(path: path).absoluteString
        print("🟢 Uploaded image → \(publicURL)")

        // Update project record
        _ = try await client
            .from("projects")
            .update(["input_image_url": AnyEncodable(publicURL)])
            .eq("id", value: projectId)
            .execute()

        print("🟣 Updated project \(projectId) with image URL")
    }

    // MARK: - Update Existing Project Fields
    func updateProject(_ id: String, fields: [String: AnyEncodable]) async throws {
        _ = try await client
            .from("projects")
            .update(fields)
            .eq("id", value: id)
            .execute()
    }

    // MARK: - Delete Project
    func deleteProject(_ id: String) async throws {
        _ = try await client
            .from("projects")
            .delete()
            .eq("id", value: id)
            .execute()
    }

    // MARK: - Generate Plan Only
    func generatePlanOnly(projectId: String) async throws -> PlanResponse {
        guard let base = URL(string: Constants.apiBase) else {
            throw URLError(.badURL)
        }
        let url = base.appendingPathComponent("generate-plan/\(projectId)")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        let (data, _) = try await URLSession.shared.data(for: request)
        return try JSONDecoder().decode(PlanResponse.self, from: data)
    }

    // MARK: - Generate Decor8 Preview
    func generatePreview(projectId: String) async throws -> String {
        guard let base = URL(string: Constants.apiBase) else {
            throw URLError(.badURL)
        }
        let url = base.appendingPathComponent("generate-preview/\(projectId)")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        let (data, _) = try await URLSession.shared.data(for: request)
        let result = try JSONDecoder().decode([String: String].self, from: data)
        guard let previewURL = result["preview_url"] else {
            throw NSError(
                domain: "ProjectsService",
                code: 104,
                userInfo: [NSLocalizedDescriptionKey: "Missing preview_url in response"]
            )
        }
        return previewURL
    }
}
