//
//  ProjectsService.swift
//  DIYGenieApp
//
//  Works with Supabase Swift v2.36.0
//

import Foundation
import UIKit
import Supabase

// MARK: - API base (read from Info.plist)
private enum AppAPI {
    static var baseURL: URL {
        guard let raw = Bundle.main.object(forInfoDictionaryKey: "API_BASE_URL") as? String,
              let url = URL(string: raw), !raw.isEmpty else {
            fatalError("Missing or invalid API_BASE_URL in Info.plist")
        }
        return url
    }
}

// MARK: - Service
struct ProjectsService {
    let userId: String
    let client: SupabaseClient

    /// Allow calls like `ProjectsService(userId: "...")` without passing a client.
    init(userId: String, client: SupabaseClient = SupabaseConfig.client) {
        self.userId = userId
        self.client = client
    }

    // MARK: Fetch list of projects for signed-in user
    func fetchProjects() async throws -> [Project] {
        // Explicit generic so `execute()` returns a typed response (not Void)
        let response: PostgrestResponse<[Project]> = try await client
            .from("projects")
            .select()
            .eq("user_id", value: userId)        // change column name if your schema differs
            .order("created_at", ascending: false)
            .execute()

        return response.value
    }

    // MARK: Upload a photo → Storage → update row
    func uploadImage(projectId: String, image: UIImage) async throws {
        guard let imageData = image.jpegData(compressionQuality: 0.85) else {
            throw NSError(domain: "ProjectsService",
                          code: 200,
                          userInfo: [NSLocalizedDescriptionKey: "Failed to compress image"])
        }

        // Storage
        let bucket = client.storage.from("uploads")
        let path = "\(userId)/\(UUID().uuidString).jpg"

        let opts = FileOptions(contentType: "image/jpeg")
        _ = try await bucket.upload(path, data: imageData, options: opts)

        // Public URL
        let publicURL = SupabaseConfig.publicURL(bucket: "uploads", path: path).absoluteString

        // Update DB
        let update: [String: AnyEncodable] = ["photo_url": AnyEncodable(publicURL)]
        _ = try await client
            .from("projects")
            .update(update)
            .eq("id", value: projectId)
            .execute()
    }

    // MARK: Trigger AI preview (server) → returns preview URL string
    /// Calls:  {API_BASE_URL}/api/projects/{id}/generate-preview
    /// Expects JSON: { "preview_url": "https://..." }
    func generatePreview(projectId: String) async throws -> String {
        let url = AppAPI.baseURL.appendingPathComponent("api/projects/\(projectId)/generate-preview")
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let (data, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw NSError(domain: "ProjectsService",
                          code: (resp as? HTTPURLResponse)?.statusCode ?? -1,
                          userInfo: [NSLocalizedDescriptionKey: "Preview failed: \(body)"])
        }

        let obj = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        return obj?["preview_url"] as? String ?? "ok"
    }

    // MARK: Trigger Plan-only (server) → returns status
    /// Calls:  {API_BASE_URL}/api/projects/{id}/generate-plan
    /// Expects JSON: { "status": "ok" }
    func generatePlanOnly(projectId: String) async throws -> String {
        let url = AppAPI.baseURL.appendingPathComponent("api/projects/\(projectId)/generate-plan")
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let (data, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw NSError(domain: "ProjectsService",
                          code: (resp as? HTTPURLResponse)?.statusCode ?? -1,
                          userInfo: [NSLocalizedDescriptionKey: "Plan failed: \(body)"])
        }

        let obj = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        return obj?["status"] as? String ?? "ok"
    }
}

