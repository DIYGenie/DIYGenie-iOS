//
//  ProjectsService.swift
//  DIYGenieApp
//

import Foundation
import UIKit
import Supabase

struct ProjectsService {
    let userId: String
    let client = SupabaseConfig.client

    // MARK: - Upload Image to Supabase Storage
    func uploadImage(projectId: String, image: UIImage) async throws {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw NSError(domain: "ProjectsService", code: 200,
                          userInfo: [NSLocalizedDescriptionKey: "Failed to compress image"])
        }

        let bucket = client.storage.from("uploads")
        let fileName = "\(userId)/\(UUID().uuidString).jpg"

        // ✅ Correct Supabase v2 API call
        _ = try await bucket.upload(
            path: fileName,
            file: imageData,
            options: UploadOptions(contentType: "image/jpeg")
        )

        // ✅ Get public URL from the bucket API
        let publicURL = client.storage.from("uploads").getPublicUrl(path: fileName)
        print("🟢 Uploaded image public URL:", publicURL)

        // ✅ Update Supabase row safely
        let updateValues: [String: AnyEncodable] = ["photo_url": AnyEncodable(publicURL)]

        _ = try await client
            .from("projects")
            .update(updateValues)
            .eq("id", value: projectId)
            .execute()
    }

    // MARK: - Fetch All Projects
    func fetchProjects() async throws -> [Project] {
        let response = try await client
            .from("projects")
            .select()
            .eq("user_id", value: userId)
            .order("created_at", ascending: false)
            .execute()

        guard let data = response.data else {
            throw NSError(domain: "ProjectsService", code: 404,
                          userInfo: [NSLocalizedDescriptionKey: "No data returned from Supabase"])
        }

        return try JSONDecoder().decode([Project].self, from: data)
    }

    // MARK: - Create Project
    func createProject(name: String, goal: String, budget: String, skillLevel: String) async throws -> Project {
        let insertValues: [String: AnyEncodable] = [
            "user_id": AnyEncodable(userId),
            "name": AnyEncodable(name),
            "goal": AnyEncodable(goal),
            "budget": AnyEncodable(budget),
            "skill_level": AnyEncodable(skillLevel),
            "status": AnyEncodable("draft")
        ]

        let response = try await client
            .from("projects")
            .insert(insertValues)
            .select()
            .single()
            .execute()

        guard let data = response.data else {
            throw NSError(domain: "ProjectsService", code: 500,
                          userInfo: [NSLocalizedDescriptionKey: "No project data returned"])
        }

        return try JSONDecoder().decode(Project.self, from: data)
    }
}

