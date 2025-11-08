//
//  ProjectsService.swift
//  DIYGenieApp
//

import Foundation
import UIKit
import Supabase

struct ProjectsService {
    // Provided by caller
    let userId: String
    let client: SupabaseClient = SupabaseConfig.client

    // Shared decoder for PostgREST responses
    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.keyDecodingStrategy = .convertFromSnakeCase
        return d
    }()

    // MARK: - Create project (returns created row)
    func createProject(name: String,
                       goal: String,
                       budget: String,
                       skillLevel: String,
                       photoURL: String? = nil) async throws -> Project {

        var payload: [String: AnyEncodable] = [
            "user_id": AnyEncodable(userId),
            "name": AnyEncodable(name),
            "goal": AnyEncodable(goal),
            "budget": AnyEncodable(budget),
            "skill_level": AnyEncodable(skillLevel),
            "is_demo": AnyEncodable(false)
        ]
        if let photoURL { payload["input_image_url"] = AnyEncodable(photoURL) }

        let resp = try await client
            .from("projects")
            .insert(payload, returning: .representation)
            .single()
            .execute()

        return try decoder.decode(Project.self, from: resp.data)
    }

    // MARK: – Fetch projects for current user
    func fetchProjects() async throws -> [Project] {
        let resp = try await client
            .from("projects")
            .select()
            .eq("user_id", value: userId)
            .order("created_at", ascending: false)
            .execute()

        return try decoder.decode([Project].self, from: resp.data)
    }

    // ProjectsService.swift  (replace the whole function)
    func uploadImage(projectId: String, image: UIImage) async throws -> String {
        guard let data = image.jpegData(compressionQuality: 0.85) else {
            throw NSError(domain: "ProjectsService", code: 200,
                          userInfo: [NSLocalizedDescriptionKey: "Failed to compress image"])
        }

        let path = "\(userId)/\(UUID().uuidString).jpg"

        // Supabase Storage: new signature is upload(path:data:options:)
        try await client.storage
            .from("uploads")
            .upload(path, data: data, options: FileOptions(contentType: "image/jpeg"))


        // AppConfig.publicURL(...) already returns a String in your app — do NOT call .absoluteString
        let publicURL = AppConfig.publicURL(bucket: "uploads", path: path)

        // persist URL on project
        let update: [String: AnyEncodable] = ["input_image_url": AnyEncodable(publicURL)]
        _ = try await client
            .from("projects")
            .update(update)
            .eq("id", value: projectId)
            .execute()

        return publicURL
    }


    // ProjectsService.swift  (put this anywhere inside struct ProjectsService)
    func saveCropRect(projectId: String, normalized: CGRect) async throws {
        let payload: [String: AnyEncodable] = [
            "crop_json": AnyEncodable([
                "x": AnyEncodable(normalized.origin.x),
                "y": AnyEncodable(normalized.origin.y),
                "w": AnyEncodable(normalized.size.width),
                "h": AnyEncodable(normalized.size.height)
            ]),
            "area_selected": AnyEncodable(true)
        ]

        _ = try await client          // ✅ prefix with client
            .from("projects")
            .update(payload)
            .eq("id", value: projectId)
            .execute()
    }


    // MARK: - Server calls (Decor8 preview + plan fetch)
    func generatePreview(projectId: String) async throws -> String {
        let url = AppConfig.apiBaseURL.appendingPathComponent("api/projects/\(projectId)/preview")
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = Data("{}".utf8)

        let (data, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse, 200..<300 ~= http.statusCode else {
            let body = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw NSError(domain: "ProjectsService", code: (resp as? HTTPURLResponse)?.statusCode ?? -1,
                          userInfo: [NSLocalizedDescriptionKey: "Preview failed: \(body)"])
        }
        let obj = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let urlString = obj?["preview_url"] as? String, !urlString.isEmpty else {
            throw NSError(domain: "ProjectsService", code: -2,
                          userInfo: [NSLocalizedDescriptionKey: "Preview OK but no preview_url returned"])
        }
        return urlString
    }

    func generatePlanOnly(projectId: String) async throws -> Bool {
        let url = AppConfig.apiBaseURL.appendingPathComponent("api/projects/\(projectId)/plan")
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = Data("{}".utf8)

        let (data, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse, 200..<300 ~= http.statusCode else {
            let body = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw NSError(domain: "ProjectsService", code: (resp as? HTTPURLResponse)?.statusCode ?? -1,
                          userInfo: [NSLocalizedDescriptionKey: "Plan-only failed: \(body)"])
        }
        return true
    }

    func fetchPlan(projectId: String) async throws -> PlanResponse {
        let url = AppConfig.apiBaseURL.appendingPathComponent("api/projects/\(projectId)/plan")
        var req = URLRequest(url: url)
        req.httpMethod = "GET"
        req.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse, 200..<300 ~= http.statusCode else {
            let body = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw NSError(domain: "ProjectsService", code: (resp as? HTTPURLResponse)?.statusCode ?? -1,
                          userInfo: [NSLocalizedDescriptionKey: "Fetch plan failed: \(body)"])
        }
        return try JSONDecoder().decode(PlanResponse.self, from: data)
    }
}

// Optional compatibility no-op
public func requestPreview(projectId: String) async throws {}

extension ProjectsService {
    // Convenience overload to avoid label mismatches in call sites
    func fetchProject(id: String) async throws -> Project { try await fetchProject(projectId: id) }

    func fetchProject(projectId: String) async throws -> Project {
        let resp = try await client
            .from("projects")
            .select()
            .eq("id", value: projectId)
            .single()
            .execute()
        return try decoder.decode(Project.self, from: resp.data)
    }
}

