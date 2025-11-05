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
enum APIBase {
    static var url: URL {
        let raw = Bundle.main.object(forInfoDictionaryKey: "API_BASE_URL") as? String ?? ""
        return URL(string: raw).flatMap { $0 } ?? URL(string: "https://example.com")!
    }
}

// MARK: - Service for project operations
struct ProjectsService {

    // NOTE: made internal so extensions in other files can access
    let userId: String
    let client: SupabaseClient

    init(userId: String, client: SupabaseClient = SupabaseConfig.client) {
        self.userId = userId
        self.client = client
    }

    // MARK: Fetch list of projects for signed-in user
    func fetchProjects() async throws -> [Project] {
        let response: PostgrestResponse<[Project]> = try await client
            .from("projects")
            .select() // all columns; add explicit list if you prefer
            .eq("user_id", value: userId)
            .order("created_at", ascending: false)
            .execute()

        return response.value
    }

    // MARK: Upload a photo → Storage → update row
    func uploadImage(projectId: String, image: UIImage) async throws {
        guard let data = image.jpegData(compressionQuality: 0.8) else {
            throw NSError(domain: "ProjectsService", code: 200,
                          userInfo: [NSLocalizedDescriptionKey: "Failed to compress image"])
        }

        let bucket = client.storage.from("uploads")
        let path = "\(userId)/\(UUID().uuidString).jpg"
        let opts = FileOptions(contentType: "image/jpeg")

        _ = try await bucket.upload(path, data: data, options: opts)

        let publicURL = SupabaseConfig.publicURL(bucket: "uploads", path: path).absoluteString
        let update: [String: AnyEncodable] = ["photo_url": AnyEncodable(publicURL)]

        _ = try await client
            .from("projects")
            .update(update)
            .eq("id", value: projectId)
            .execute()
    }

    // MARK: Trigger AI preview (server) -> preview URL String
    func generatePreview(projectId: String) async throws -> String {
        let url = APIBase.url.appendingPathComponent("api/projects/\(projectId)/generate-preview")
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let (data, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw NSError(domain: "ProjectsService",
                          code: (resp as? HTTPURLResponse)?.statusCode ?? -1,
                          userInfo: [NSLocalizedDescriptionKey: "Preview failed: \(body)"])
        }

        let obj = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        return (obj?["preview_url"] as? String) ?? ""
    }

    // MARK: Trigger Plan-only (server) -> full PlanResponse
    func generatePlanOnly(projectId: String) async throws -> PlanResponse {
        let url = APIBase.url.appendingPathComponent("api/projects/\(projectId)/generate-plan")
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let (data, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw NSError(domain: "ProjectsService",
                          code: (resp as? HTTPURLResponse)?.statusCode ?? -1,
                          userInfo: [NSLocalizedDescriptionKey: "Plan failed: \(body)"])
        }

        return try JSONDecoder().decode(PlanResponse.self, from: data)
    }
}

