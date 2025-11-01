//
//  ProjectsService.swift
//  DIYGenieApp
//
//  Works with Supabase Swift v2.36.0
//

import Foundation
import UIKit
import Supabase

// MARK: - App / Supabase config (reads from Info.plist)
enum AppConfig {
    /// e.g. https://api.yourdomain.com
    static var apiBaseURL: URL {
        let raw = Bundle.main.object(forInfoDictionaryKey: "API_BASE_URL") as? String ?? ""
        // Intentionally crash early if misconfigured in production.
        guard let url = URL(string: raw), !raw.isEmpty else {
            preconditionFailure("Missing or invalid Info.plist key: API_BASE_URL")
        }
        return url
    }
}

enum SupabaseConfig {
    /// Base URL of your Supabase project, e.g. https://xxxxx.supabase.co
    static var baseURL: URL {
        let raw = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_URL") as? String ?? ""
        guard let url = URL(string: raw), !raw.isEmpty else {
            preconditionFailure("Missing or invalid Info.plist key: SUPABASE_URL")
        }
        return url
    }

    /// Anonymous key (safe to ship in client apps)
    static var anonKey: String {
        let key = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_ANON_KEY") as? String ?? ""
        guard !key.isEmpty else {
            preconditionFailure("Missing Info.plist key: SUPABASE_ANON_KEY")
        }
        return key
    }

    /// Shared Supabase client
    static let client: SupabaseClient = {
        SupabaseClient(supabaseURL: baseURL, supabaseKey: anonKey)
    }()

    /// Build a public Storage URL (SDK no longer exposes getPublicUrl)
    static func publicURL(bucket: String, path: String) -> String {
        baseURL
            .appendingPathComponent("storage/v1/object/public/\(bucket)/\(path)")
            .absoluteString
    }
}

// MARK: - Service
struct ProjectsService {
    let userId: String
    let client = SupabaseConfig.client

    // MARK: Upload Image → Storage → update row
    func uploadImage(projectId: String, image: UIImage) async throws {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw NSError(
                domain: "ProjectsService",
                code: 200,
                userInfo: [NSLocalizedDescriptionKey: "Failed to compress image"]
            )
        }

        let bucket = client.storage.from("uploads")
        let path = "\(userId)/\(UUID().uuidString).jpg"

        // Supabase v2.36.0 signature: upload(_ path: String, data: Data, options: FileOptions?)
        _ = try await bucket.upload(
            path,
            data: imageData,
            options: .init(contentType: "image/jpeg")
        )

        let publicURL = SupabaseConfig.publicURL(bucket: "uploads", path: path)

        let update: [String: AnyEncodable] = ["photo_url": AnyEncodable(publicURL)]
        _ = try await client
            .from("projects")
            .update(update)
            .eq("id", value: projectId)
            .execute()
    }

    // MARK: Trigger AI preview (server)
    /// POST {API_BASE_URL}/api/projects/{id}/generate-preview
    /// Expects: { "preview_url": "https://..." }
    func generatePreview(projectId: String) async throws -> String {
        let url = AppConfig.apiBaseURL
            .appendingPathComponent("api/projects/\(projectId)/generate-preview")

        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let (data, response) = try await URLSession.shared.data(for: req)
        guard let resp = response as? HTTPURLResponse, (200..<300).contains(resp.statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw NSError(
                domain: "ProjectsService",
                code: (response as? HTTPURLResponse)?.statusCode ?? -1,
                userInfo: [NSLocalizedDescriptionKey: "Request failed: \(body)"]
            )
        }

        let obj = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        return (obj?["preview_url"] as? String) ?? "ok"
    }

    // MARK: Trigger Plan-only (server)
    /// POST {API_BASE_URL}/api/projects/{id}/generate-plan
    /// Expects: { "status": "ok" }
    func generatePlanOnly(projectId: String) async throws -> String {
        let url = AppConfig.apiBaseURL
            .appendingPathComponent("api/projects/\(projectId)/generate-plan")

        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let (data, response) = try await URLSession.shared.data(for: req)
        guard let resp = response as? HTTPURLResponse, (200..<300).contains(resp.statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw NSError(
                domain: "ProjectsService",
                code: (response as? HTTPURLResponse)?.statusCode ?? -1,
                userInfo: [NSLocalizedDescriptionKey: "Request failed: \(body)"]
            )
        }

        let obj = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        return (obj?["status"] as? String) ?? "ok"
    }
}

