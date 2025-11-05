//
//  ProjectsService.swift
//  DIYGenieApp
//
//  Supabase Swift v2.36.x
//

import Foundation
import UIKit
import Supabase

// MARK: - Service

struct ProjectsService {
    private let userId: String
    private let client: SupabaseClient

    init(userId: String, client: SupabaseClient = SupabaseConfig.client) {
        self.userId = userId
        self.client = client
    }

    // MARK: Fetch list of projects for the signed-in user
    func fetchProjects() async throws -> [Project] {
        let response: PostgrestResponse<[Project]> = try await client
            .from("projects")
            .select()
            .eq("user_id", value: userId)
            .order("created_at", ascending: false)
            .execute()
        return response.value
    }

    // MARK: Upload photo → Storage → update row.photo_url
    func uploadImage(projectId: String, image: UIImage) async throws {
        guard let data = image.jpegData(compressionQuality: 0.85) else {
            throw NSError(domain: "ProjectsService", code: 200, userInfo: [NSLocalizedDescriptionKey: "Image compression failed"])
        }

        let path = "\(userId)/\(UUID().uuidString).jpg"
        let bucket = client.storage.from("uploads")

        _ = try await bucket.upload(
            path,
            data: data,
            options: .init(contentType: "image/jpeg")
        )

        let publicURL = SupabaseConfig.publicURL(bucket: "uploads", path: path)

        let update: [String: AnyEncodable] = ["photo_url": AnyEncodable(publicURL.absoluteString)]
        _ = try await client
            .from("projects")
            .update(update)
            .eq("id", value: projectId)
            .execute()
    }

    // MARK: Trigger AI preview (server) → returns preview URL string
    func generatePreview(projectId: String) async throws -> String {
        var req = URLRequest(url: try apiURL(path: "api/projects/\(projectId)/generate-preview"))
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let (data, response) = try await URLSession.shared.data(for: req)
        guard let http = response as? HTTPURLResponse, 200..<300 ~= http.statusCode else {
            let body = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw NSError(domain: "ProjectsService", code: (response as? HTTPURLResponse)?.statusCode ?? -1, userInfo: [NSLocalizedDescriptionKey: "Preview failed: \(body)"])
        }

        // Accept either { "preview_url": "…" } or a direct string
        if let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let url = obj["preview_url"] as? String {
            return url
        }
        if let url = String(data: data, encoding: .utf8) {
            return url
        }
        throw NSError(domain: "ProjectsService", code: 500, userInfo: [NSLocalizedDescriptionKey: "Preview response missing URL"])
    }

    // MARK: Trigger Plan generation (server) → returns full PlanResponse
    func generatePlanOnly(projectId: String) async throws -> PlanResponse {
        var req = URLRequest(url: try apiURL(path: "api/projects/\(projectId)/generate-plan"))
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let (data, response) = try await URLSession.shared.data(for: req)
        guard let http = response as? HTTPURLResponse, 200..<300 ~= http.statusCode else {
            let body = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw NSError(domain: "ProjectsService", code: (response as? HTTPURLResponse)?.statusCode ?? -1, userInfo: [NSLocalizedDescriptionKey: "Plan failed: \(body)"])
        }

        let decoder = JSONDecoder()
        // 1) Try to decode a raw PlanResponse
        if let direct = try? decoder.decode(PlanResponse.self, from: data) {
            return direct
        }
        // 2) Try to decode { "plan": PlanResponse }
        struct PlanEnvelope: Decodable { let plan: PlanResponse }
        if let wrapped = try? decoder.decode(PlanEnvelope.self, from: data) {
            return wrapped.plan
        }
        // 3) Try to read from { "plan_json": … }
        struct PlanJSONEnvelope: Decodable { let plan_json: PlanResponse }
        if let wrapped = try? decoder.decode(PlanJSONEnvelope.self, from: data) {
            return wrapped.plan_json
        }

        let body = String(data: data, encoding: .utf8) ?? ""
        throw NSError(domain: "ProjectsService", code: 422, userInfo: [NSLocalizedDescriptionKey: "Unexpected plan payload: \(body.prefix(400))"])
    }

    // MARK: - Private
    private func apiURL(path: String) throws -> URL {
        guard
            let raw = Bundle.main.object(forInfoDictionaryKey: "API_BASE_URL") as? String,
            let base = URL(string: raw)
        else {
            throw NSError(domain: "ProjectsService", code: 100, userInfo: [NSLocalizedDescriptionKey: "Missing API_BASE_URL in Info.plist"])
        }
        return base.appendingPathComponent(path)
    }
}
