//
//  ProjectsService.swift
//  DIYGenieApp
//

import Foundation
import Supabase
import UIKit

struct ProjectsService {
    let userId: String
    let client = SupabaseConfig.client

    // MARK: - Fetch All Projects
    func fetchProjects() async throws -> [Project] {
        let response = try await client
            .from("projects")
            .select()
            .eq("user_id", value: userId)
            .order("created_at", ascending: false)
            .execute()

        // New Supabase SDK already returns non-optional Data
        guard !response.data.isEmpty else {
            throw NSError(
                domain: "ProjectsService",
                code: 100,
                userInfo: [NSLocalizedDescriptionKey: "No data returned from Supabase"]
            )
        }

        let projects = try JSONDecoder().decode([Project].self, from: response.data)
        return projects
    }

    // MARK: - Create Project
    func createProject(name: String, goal: String, budget: String, skillLevel: String) async throws -> Project {
        let insert: [String: AnyEncodable] = [
            "user_id": AnyEncodable(userId),
            "name": AnyEncodable(name),
            "goal": AnyEncodable(goal),
            "budget": AnyEncodable(budget),
            "skill_level": AnyEncodable(skillLevel),
            "status": AnyEncodable("draft"),
            "created_at": AnyEncodable(Date().ISO8601Format())
        ]

        let response = try await client
            .from("projects")
            .insert([insert])
            .select()
            .single()
            .execute()

        let project = try JSONDecoder().decode(Project.self, from: response.data)
        return project
    }

    // MARK: - Upload Image
    func uploadImage(projectId: String, image: UIImage) async throws {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw NSError(domain: "ProjectsService", code: 200, userInfo: [NSLocalizedDescriptionKey: "Failed to compress image"])
        }

        let bucket = client.storage.from("uploads")
        let path = "\(userId)/\(UUID().uuidString).jpg"

        _ = try await bucket.upload(path: path, file: imageData, options: FileOptions(contentType: "image/jpeg"))

        let publicURL = bucket.getPublicUrl(path: path)
        let urlString = publicURL.absoluteString

        _ = try await client
            .from("projects")
            .update(["photo_url": AnyEncodable(urlString)])
            .eq("id", value: projectId)
            .execute()
    }

    // MARK: - Generate AI Preview
    func generatePreview(projectId: String) async throws -> String {
        let url = URL(string: "\(API.baseURL)/api/projects/\(projectId)/generate-preview")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        let (_, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw NSError(domain: "ProjectsService", code: 300, userInfo: [NSLocalizedDescriptionKey: "Preview generation failed"])
        }
        return "\(API.baseURL)/projects/\(projectId)"
    }

    // MARK: - Generate Plan Only
    func generatePlanOnly(projectId: String) async throws -> Bool {
        let url = URL(string: "\(API.baseURL)/api/projects/\(projectId)/generate-plan")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        let (_, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw NSError(domain: "ProjectsService", code: 301, userInfo: [NSLocalizedDescriptionKey: "Plan generation failed"])
        }
        return true
    }
}

