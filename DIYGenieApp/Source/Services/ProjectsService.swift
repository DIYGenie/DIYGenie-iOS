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

    // MARK: - Create Project
    func createProject(name: String, goal: String, budget: String, skillLevel: String) async throws -> Project {
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

        guard let data = response.data else {
            throw NSError(domain: "ProjectsService", code: 500, userInfo: [NSLocalizedDescriptionKey: "Empty response from Supabase"])
        }

        return try JSONDecoder().decode(Project.self, from: data)
    }

    // MARK: - Upload Image
    func uploadImage(projectId: String, image: UIImage) async throws {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw NSError(domain: "ProjectsService", code: 200, userInfo: [NSLocalizedDescriptionKey: "Failed to compress image"])
        }

        let bucket = client.storage.from("uploads")
        let path = "\(userId)/\(UUID().uuidString).jpg"

        // ✅ Updated upload syntax for Supabase v2.5+
        _ = try await bucket.upload(path, data: imageData, options: UploadOptions(contentType: "image/jpeg"))

        // ✅ Get public URL using new return type
        let publicURL = bucket.getPublicUrl(path)

        // ✅ Update photo_url in projects table
        _ = try await client
            .from("projects")
            .update(["photo_url": AnyEncodable(publicURL)])
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

        // ✅ New SDK returns non-optional Data
        let data = response.data

        // Decode safely
        return try JSONDecoder().decode([Project].self, from: data)
    }
}

