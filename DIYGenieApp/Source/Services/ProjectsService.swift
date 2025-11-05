//
//  ProjectsService.swift
//  DIYGenieApp
//
//  Supabase + API service (fixed routes):
//  - POST  {API_BASE_URL}/api/projects/{id}/preview   -> triggers Decor8 preview; returns { preview_url }
//  - GET   {API_BASE_URL}/api/projects/{id}/plan      -> returns saved plan_json (PlanResponse)
//

import Foundation
import UIKit
import Supabase

// MARK: - App / Supabase config helpers (read from Info.plist)

enum AppConfig {
    static var apiBaseURL: URL {
        let raw = Bundle.main.object(forInfoDictionaryKey: "API_BASE_URL") as? String ?? ""
        guard let url = URL(string: raw) else {
            fatalError("❌ API_BASE_URL missing/invalid in Info.plist")
        }
        return url
    }
}

enum SupabaseEnv {
    static var baseURL: URL {
        let raw = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_URL") as? String ?? ""
        guard let url = URL(string: raw) else {
            fatalError("❌ SUPABASE_URL missing/invalid in Info.plist")
        }
        return url
    }

    static func publicURL(bucket: String, path: String) -> String {
        baseURL
            .appendingPathComponent("storage/v1/object/public")
            .appendingPathComponent(bucket)
            .appendingPathComponent(path)
            .absoluteString
    }
}

// MARK: - Service

struct ProjectsService {
    let userId: String
    private let client: SupabaseClient = SupabaseConfig.client   // you already have this

    // MARK: Create project (returns created row)
    func createProject(name: String, goal: String, budget: String, skillLevel: String) async throws -> Project {
        let payload: [String: AnyEncodable] = [
            "user_id": AnyEncodable(userId),
            "name": AnyEncodable(name),
            "goal": AnyEncodable(goal),
            "budget": AnyEncodable(budget),
            "skilllevel": AnyEncodable(skillLevel),
            "is_demo": AnyEncodable(false)
        ]

        let resp: PostgrestResponse<Project> = try await client
            .from("projects")
            .insert(payload, returning: .representation)
            .single()
            .execute(decoding: Project.self)

        guard let project = resp.value else {
            throw NSError(domain: "ProjectsService", code: -10,
                          userInfo: [NSLocalizedDescriptionKey: "Empty response from insert()"])
        }
        return project
    }

    // MARK: Fetch projects for current user
    func fetchProjects() async throws -> [Project] {
        let resp: PostgrestResponse<[Project]> = try await client
            .from("projects")
            .select()
            .eq("user_id", value: userId)
            .order("created_at", ascending: false)
            .execute(decoding: [Project].self)

        guard let list = resp.value else {
            throw NSError(domain: "ProjectsService", code: -11,
                          userInfo: [NSLocalizedDescriptionKey: "Empty response from select()"])
        }
        return list
    }

    // MARK: Upload image -> Storage, save public URL on project.input_image_url
    func uploadImage(projectId: String, image: UIImage) async throws {
        guard let data = image.jpegData(compressionQuality: 0.85) else {
            throw NSError(domain: "ProjectsService", code: 200,
                          userInfo: [NSLocalizedDescriptionKey: "Failed to compress image"])
        }

        let path = "\(userId)/\(UUID().uuidString).jpg"

        _ = try await client.storage
            .from("uploads")
            .upload(path: path, file: data, options: FileOptions(contentType: "image/jpeg"))

        let publicURL = SupabaseEnv.publicURL(bucket: "uploads", path: path)

        let update: [String: AnyEncodable] = ["input_image_url": AnyEncodable(publicURL)]
        _ = try await client
            .from("projects")
            .update(update)
            .eq("id", value: projectId)
            .execute()
    }

    // MARK: Trigger Decor8 Preview on backend (POST /api/projects/{id}/preview)
    // Backend also persists preview_url to the row; we return it for immediate UI.
    func generatePreview(projectId: String) async throws -> String {
        var url = AppConfig.apiBaseURL
        url.appendPathComponent("api/projects")
        url.appendPathComponent(projectId)
        url.appendPathComponent("preview")

        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let (data, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse else {
            throw NSError(domain: "ProjectsService", code: -1,
                          userInfo: [NSLocalizedDescriptionKey: "No HTTP response"])
        }
        guard 200..<300 ~= http.statusCode else {
            let body = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw NSError(domain: "ProjectsService", code: http.statusCode,
                          userInfo: [NSLocalizedDescriptionKey: "Preview failed: \(body)"])
        }

        let obj = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let urlString = obj?["preview_url"] as? String ?? ""
        guard !urlString.isEmpty else {
            throw NSError(domain: "ProjectsService", code: -2,
                          userInfo: [NSLocalizedDescriptionKey: "Preview OK but no preview_url returned"])
        }
        return urlString
    }

    // MARK: Fetch saved plan (GET /api/projects/{id}/plan)
    func fetchPlan(projectId: String) async throws -> PlanResponse {
        var url = AppConfig.apiBaseURL
        url.appendPathComponent("api/projects")
        url.appendPathComponent(projectId)
        url.appendPathComponent("plan")

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
