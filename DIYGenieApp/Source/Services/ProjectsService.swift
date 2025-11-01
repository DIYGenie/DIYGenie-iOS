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
    /// Base URL of your app/backend, injected via Info.plist (API_BASE_URL).
    static var apiBaseURL: URL {
        let raw = Bundle.main.object(forInfoDictionaryKey: "API_BASE_URL") as? String ?? ""
        return URL(string: raw) ?? URL(string: "https://example.com")! // must exist at runtime
    }
}

/// Uses the shared `SupabaseConfig.client` and `SupabaseConfig.publicURL(bucket:path:)`
/// defined in **SupabaseConfig.swift** (do not duplicate that type here).
struct ProjectsService {
    let userId: String
    let client = SupabaseConfig.client

    // MARK: - Upload Image (photo) → Storage → update row
    func uploadImage(projectId: String, image: UIImage) async throws {
        // 1) JPEG data
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw NSError(domain: "ProjectsService",
                          code: 200,
                          userInfo: [NSLocalizedDescriptionKey: "Failed to compress image"])
        }

        // 2) Destination
        let bucket = client.storage.from("uploads")
        let path = "\(userId)/\(UUID().uuidString).jpg"

        // 3) Upload (current SDK signature)
        let opts = FileOptions(contentType: "image/jpeg")
        _ = try await bucket.upload(
            path,
            data: imageData,
            options: opts
        )

        // 4) Build a public URL (SDK no longer provides getPublicUrl)
        let publicURL = SupabaseConfig.publicURL(bucket: "uploads", path: path)

        // 5) Update project row
        let update: [String: AnyEncodable] = ["photo_url": AnyEncodable(publicURL)]
        _ = try await client
            .from("projects")
            .update(update)
            .eq("id", value: projectId)
            .execute()
    }

    // MARK: - Trigger AI preview (server)
    /// Calls:  {API_BASE_URL}/api/projects/{id}/generate-preview
    /// Expects JSON like: { "preview_url": "https://..." }
    func generatePreview(projectId: String) async throws -> String {
        let url = AppConfig.apiBaseURL
            .appendingPathComponent("api/projects/\(projectId)/generate-preview")

        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let (data, response) = try await URLSession.shared.data(for: req)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw NSError(
                domain: "ProjectsService",
                code: (response as? HTTPURLResponse)?.statusCode ?? -1,
                userInfo: [NSLocalizedDescriptionKey: "Preview failed: \(body)"]
            )
        }

        let obj = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let urlString = obj?["preview_url"] as? String ?? "ok"
        return urlString
    }

    // MARK: - Trigger Plan-only (server)
    /// Calls:  {API_BASE_URL}/api/projects/{id}/generate-plan
    /// Expects JSON like: { "status": "ok" }
    func generatePlanOnly(projectId: String) async throws -> String {
        let url = AppConfig.apiBaseURL
            .appendingPathComponent("api/projects/\(projectId)/generate-plan")

        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let (data, response) = try await URLSession.shared.data(for: req)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw NSError(
                domain: "ProjectsService",
                code: (response as? HTTPURLResponse)?.statusCode ?? -1,
                userInfo: [NSLocalizedDescriptionKey: "Plan failed: \(body)"]
            )
        }

        let obj = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let status = obj?["status"] as? String ?? "ok"
        return status
    }
}
