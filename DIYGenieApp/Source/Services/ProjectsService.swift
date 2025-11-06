//
//  ProjectsService.swift
//  DIYGenieApp
//

import Foundation
import UIKit
import Supabase

// MARK: - App / Supabase config helpers
enum AppConfig {
    static var apiBaseURL: URL {
        let raw = Bundle.main.object(forInfoDictionaryKey: "API_BASE_URL") as? String ?? ""
        guard let url = URL(string: raw) else {
            fatalError("❌ Missing/invalid API_BASE_URL in Info.plist")
        }
        return url
    }
}

enum SupabaseEnv {
    static var baseURL: URL {
        let raw = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_URL") as? String ?? ""
        guard let url = URL(string: raw) else {
            fatalError("❌ Missing/invalid SUPABASE_URL in Info.plist")
        }
        return url
    }
    static func publicURL(bucket: String, path: String) -> URL {
        baseURL.appendingPathComponent("storage/v1/object/public/\(bucket)/\(path)")
    }
}

struct ProjectsService {

    // ✅ Provided by caller
    let userId: String
    let client: SupabaseClient = SupabaseConfig.client

    // Shared decoder for PostgREST responses
    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.keyDecodingStrategy = .convertFromSnakeCase
        return d
    }()

    // MARK: - Create project (returns created row)
    func createProject(name: String, goal: String, budget: String, skillLevel: String) async throws -> Project {
        let payload: [String: AnyEncodable] = [
            "user_id": AnyEncodable(userId),
            "name": AnyEncodable(name),
            "goal": AnyEncodable(goal),
            "budget": AnyEncodable(budget),
            // 🔧 FIX: correct column name
            "skill_level": AnyEncodable(skillLevel),
            "is_demo": AnyEncodable(false)
        ]

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

    // MARK: - Upload image -> Storage, save public URL on project
    func uploadImage(projectId: String, image: UIImage) async throws {
        guard let data = image.jpegData(compressionQuality: 0.85) else {
            throw NSError(domain: "ProjectsService", code: 200,
                          userInfo: [NSLocalizedDescriptionKey: "Failed to compress image"])
        }

        let path = "\(userId)/\(UUID().uuidString).jpg"

        // Supabase Storage upload (new signature is path:file:options:)
        try await client.storage
            .from("uploads")
            .upload(path: path, file: data, options: FileOptions(contentType: "image/jpeg"))

        let publicURL = SupabaseEnv.publicURL(bucket: "uploads", path: path).absoluteString

        let update: [String: AnyEncodable] = ["input_image_url": AnyEncodable(publicURL)]
        _ = try await client
            .from("projects")
            .update(update)
            .eq("id", value: projectId)
            .execute()
    }

    // MARK: - Server calls (Decor8 preview + plan fetch)

    /// POST {API}/api/projects/{id}/preview  -> { preview_url }
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
        let urlString = obj?["preview_url"] as? String ?? ""
        if urlString.isEmpty {
            throw NSError(domain: "ProjectsService", code: -2,
                          userInfo: [NSLocalizedDescriptionKey: "Preview OK but no preview_url returned"])
        }
        return urlString
    }

    /// POST {API}/api/projects/{id}/plan  -> triggers plan generation without preview
    /// Returns true on any 2xx response.
    func generatePlanOnly(projectId: String) async throws -> Bool {
        let url = AppConfig.apiBaseURL.appendingPathComponent("api/projects/\(projectId)/plan")
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        // Legacy handler may accept empty JSON body.
        req.httpBody = Data("{}".utf8)

        let (data, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse, 200..<300 ~= http.statusCode else {
            let body = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw NSError(domain: "ProjectsService", code: (resp as? HTTPURLResponse)?.statusCode ?? -1,
                          userInfo: [NSLocalizedDescriptionKey: "Plan-only failed: \(body)"])
        }
        return true
    }

    /// GET {API}/api/projects/{id}/plan -> PlanResponse (saved plan_json)
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
// Optional: queue a preview on the backend (no-op stub for now)
public func requestPreview(projectId: String) async throws {
    // Wire this to your backend later; safe no-op for compile/run.
}
