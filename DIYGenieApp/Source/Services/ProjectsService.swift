//
//  ProjectsService.swift
//  DIYGenieApp
//
//  Works with Supabase Swift v2.36.0
//

import Foundation
import UIKit
import Supabase

// MARK: - App config (no secrets in code)
enum AppConfig {
    /// Your backend base URL (e.g. https://api.diygenie.app)
    static var apiBaseURL: URL {
        let raw = Bundle.main.object(forInfoDictionaryKey: "API_BASE_URL") as? String ?? ""
        return URL(string: raw) ?? URL(string: "https://example.com")!  // must exist at runtime
    }

    /// Supabase project base URL (e.g. https://xxxx.supabase.co)
    static var supabaseBaseURL: URL {
        let raw = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_URL") as? String ?? ""
        return URL(string: raw) ?? URL(string: "https://example.supabase.co")!
    }
}

/// Build a *public* storage URL (SDK no longer exposes getPublicUrl)
enum StoragePublicURL {
    static func build(baseURL: URL, bucket: String, path: String) -> URL {
        baseURL
            .appendingPathComponent("storage/v1/object/public/\(bucket)/\(path)")
    }
}


// MARK: - Service
struct ProjectsService {

    // Inject what this service needs — avoids redeclaring SupabaseConfig here.
    let userId: String
    let client: SupabaseClient

    init(userId: String, client: SupabaseClient) {
        self.userId = userId
        self.client = client
    }

    // MARK: Fetch list of projects for signed-in user
    func fetchProjects() async throws -> [Project] {
        // Explicit generic so execute() returns a typed response (not Void)
        let response: PostgrestResponse<[Project]> = try await client
            .from("projects")
            .select() // all columns; add "*, other_table(*)" if needed
            .eq("user_id", value: userId) // change column name if your schema differs
            .order("created_at", ascending: false)
            .execute()

        return response.value
    }

    // MARK: Upload a photo -> Storage -> update row
    func uploadImage(projectId: String, image: UIImage) async throws {
        guard let data = image.jpegData(compressionQuality: 0.8) else {
            throw NSError(domain: "ProjectsService", code: 200,
                          userInfo: [NSLocalizedDescriptionKey: "Failed to compress image"])
        }

        let bucket = client.storage.from("uploads")
        let path = "\(userId)/\(UUID().uuidString).jpg"

        _ = try await bucket.upload(
            path,
            data: data,
            options: .init(contentType: "image/jpeg")
        )

        let publicURL = StoragePublicURL.build(
            baseURL: AppConfig.supabaseBaseURL,
            bucket: "uploads",
            path: path
        ).absoluteString

        let update: [String: AnyEncodable] = ["photo_url": AnyEncodable(publicURL)]

        _ = try await client
            .from("projects")
            .update(update)
            .eq("id", value: projectId)
            .execute()
    }

    // MARK: Trigger AI preview (server) -> returns preview URL string
    // Calls: {API_BASE_URL}/api/projects/{id}/generate-preview
    // Expects: { "preview_url": "https://..." }
    func generatePreview(projectId: String) async throws -> String {
        let url = AppConfig.apiBaseURL
            .appendingPathComponent("api/projects/\(projectId)/generate-preview")

        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let (data, response) = try await URLSession.shared.data(for: req)

        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw NSError(domain: "ProjectsService",
                          code: (response as? HTTPURLResponse)?.statusCode ?? -1,
                          userInfo: [NSLocalizedDescriptionKey: "Preview failed: \(body)"])
        }

        let obj = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        return (obj?["preview_url"] as? String) ?? "ok"
    }

    // MARK: Trigger Plan-only (server) -> returns status string
    // Calls: {API_BASE_URL}/api/projects/{id}/generate-plan
    // Expects: { "status": "ok" }
    func generatePlanOnly(projectId: String) async throws -> String {
        let url = AppConfig.apiBaseURL
            .appendingPathComponent("api/projects/\(projectId)/generate-plan")

        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let (data, response) = try await URLSession.shared.data(for: req)

        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw NSError(domain: "ProjectsService",
                          code: (response as? HTTPURLResponse)?.statusCode ?? -1,
                          userInfo: [NSLocalizedDescriptionKey: "Plan failed: \(body)"])
        }

        let obj = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        return (obj?["status"] as? String) ?? "ok"
    }
}
