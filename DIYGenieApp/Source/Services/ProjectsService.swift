//
//  ProjectsService.swift
//  DIYGenieApp
//

import Foundation
import UIKit
import Supabase

// MARK: - SupabaseConfig helper must expose base URL + client
// SupabaseConfig.client  : SupabaseClient
// SupabaseConfig.baseURL : URL   (derived from Info.plist SUPABASE_URL)
private extension SupabaseConfig {
    static func publicURL(bucket: String, path: String) -> String {
        // <SUPABASE_URL>/storage/v1/object/public/<bucket>/<path>
        baseURL
            .appendingPathComponent("storage/v1/object/public/\(bucket)/\(path)")
            .absoluteString
    }
}

struct ProjectsService {
    let userId: String
    let client = SupabaseConfig.client

    // MARK: - Create Project
    func createProject(
        name: String,
        goal: String,
        budget: String,
        skillLevel: String
    ) async throws -> Project {
        let values: [String: AnyEncodable] = [
            "user_id": AnyEncodable(userId),
            "name": AnyEncodable(name),
            "goal": AnyEncodable(goal),
            "budget": AnyEncodable(budget),
            "skill_level": AnyEncodable(skillLevel),
            "status": AnyEncodable("draft")
        ]

        let res = try await client
            .from("projects")
            .insert(values)
            .select()
            .single()
            .execute()

        return try JSONDecoder().decode(Project.self, from: res.data)
    }

    // MARK: - Fetch Projects
    func fetchProjects() async throws -> [Project] {
        let res = try await client
            .from("projects")
            .select()
            .eq("user_id", value: userId)
            .order("created_at", ascending: false)
            .execute()

        return try JSONDecoder().decode([Project].self, from: res.data)
    }

    // MARK: - Upload Image (photo) → Storage + update row
    func uploadImage(projectId: String, image: UIImage) async throws {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw NSError(domain: "ProjectsService", code: 200,
                          userInfo: [NSLocalizedDescriptionKey: "Failed to compress image"])
        }

        let bucket = client.storage.from("uploads")
        let path = "\(userId)/\(UUID().uuidString).jpg"

        // Upload with current SDK
        _ = try await bucket.upload(
            path,
            data: imageData,
            options: .init(contentType: "image/jpeg")
        )

        // Build public URL manually (no more getPublicUrl headaches)
        let publicURL = SupabaseConfig.publicURL(bucket: "uploads", path: path)

        let update: [String: AnyEncodable] = ["photo_url": AnyEncodable(publicURL)]
        _ = try await client
            .from("projects")
            .update(update)
            .eq("id", value: projectId)
            .execute()
    }

    // MARK: - Trigger AI preview (server)
    func generatePreview(projectId: String) async throws -> String {
        // Hitting your webhook/API (base is set in Constants/API, or inline build here)
        guard let url = URL(string: "\(API.baseURL)/api/projects/\(projectId)/generate-preview") else {
            throw NSError(domain: "ProjectsService", code: 400,
                          userInfo: [NSLocalizedDescriptionKey: "Bad preview URL"])
        }

        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let (data, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse, 200..<300 ~= http.statusCode else {
            let body = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw NSError(domain: "ProjectsService", code: http.statusCode,
                          userInfo: [NSLocalizedDescriptionKey: "Preview failed: \(body)"])
        }

        // Expecting { "preview_url": "https://..." } or similar
        let obj = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let urlString = obj?["preview_url"] as? String ?? "ok"
        return urlString
    }

    // MARK: - Trigger Plan-only (server)
    func generatePlanOnly(projectId: String) async throws -> String {
        guard let url = URL(string: "\(API.baseURL)/api/projects/\(projectId)/generate-plan") else {
            throw NSError(domain: "ProjectsService", code: 400,
                          userInfo: [NSLocalizedDescriptionKey: "Bad plan URL"])
        }

        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let (data, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse, 200..<300 ~= http.statusCode else {
            let body = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw NSError(domain: "ProjectsService", code: http.statusCode,
                          userInfo: [NSLocalizedDescriptionKey: "Plan failed: \(body)"])
        }

        let obj = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let status = obj?["status"] as? String ?? "ok"
        return status
    }
}

