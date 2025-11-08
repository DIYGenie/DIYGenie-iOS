//
//  ProjectsService.swift
//  DIYGenieApp
//
//  Consolidated service (storage + REST + DIYGenie API) — no PostgREST dependency.
//  Uses Supabase Storage via `Supabase` SDK and REST with URLSession for rows.
//

import Foundation
import UIKit
import Supabase

struct ProjectsService {
    // MARK: - Init / shared
    let userId: String
    private let client = SupabaseClient(supabaseURL: AppConfig.supabaseURL, supabaseKey: AppConfig.supabaseAnonKey)

    // MARK: - Models (lightweight)
    struct CreateRow: Codable {
        let name: String
        let goal: String
        let budget: String
        let skill_level: String
        let user_id: String
        let photo_url: String?
    }
    struct RowWithID: Codable { let id: String }
    struct Rows<T: Decodable>: Decodable { let items: [T]? } // not used, but handy

    // MARK: - Create
    func createProject(name: String,
                       goal: String,
                       budget: String,
                       skillLevel: String) async throws -> Project {
        let body = CreateRow(
            name: name,
            goal: goal,
            budget: budget,
            skill_level: skillLevel,
            user_id: userId,
            photo_url: nil
        )

        var req = URLRequest(url: AppConfig.supabaseURL
            .appendingPathComponent("rest/v1/projects"))
        req.httpMethod = "POST"
        AppConfig.supabaseHeaders.forEach { req.setValue($1, forHTTPHeaderField: $0) }
        req.setValue("return=representation", forHTTPHeaderField: "Prefer")
        req.httpBody = try JSONEncoder().encode(body)

        let (data, resp) = try await URLSession.shared.data(for: req)
        try Self.ensure2xx(resp, data: data, context: "Create project")

        let created = try JSONDecoder().decode([Project].self, from: data)
        guard let first = created.first else {
            throw Self.err("Create succeeded but no row returned.")
        }
        return first
    }

    // MARK: - Upload photo → Storage (public ‘uploads’) → PATCH project.photo_url
    @discardableResult
    func uploadImage(projectId: String, image: UIImage) async throws -> String {
        guard let data = image.jpegData(compressionQuality: 0.88) else {
            throw Self.err("Failed to compress image.")
        }
        let path = "\(userId)/\(UUID().uuidString).jpg"

        // Storage upload
        _ = try await client.storage
            .from("uploads")
            .upload(path, data: data, options: FileOptions(contentType: "image/jpeg"))

        // Public URL
        let publicURL = SupabaseConfig.publicURL(bucket: "uploads", path: path).absoluteString

        // Patch project
        try await patchProject(projectId, ["photo_url": publicURL])

        return publicURL
    }

    // MARK: - Optional crop rect (best effort; ignore failures)
    func attachCropRectIfAvailable(projectId: String, rect: CGRect) async {
        let payload: [String: Any] = [
            "crop_rect": [
                "x": rect.origin.x, "y": rect.origin.y,
                "w": rect.size.width, "h": rect.size.height
            ]
        ]
        do { try await patchProject(projectId, payload) }
        catch { print("attachCropRectIfAvailable skipped → \(error.localizedDescription)") }
    }

    // MARK: - Upload RoomPlan .usdz → scan_json / ar_provider
    func uploadARScan(projectId: String, fileURL: URL) async throws {
        let data = try Data(contentsOf: fileURL)
        let path = "\(userId)/\(UUID().uuidString).usdz"

        _ = try await client.storage
            .from("uploads")
            .upload(path, data: data, options: FileOptions(contentType: "model/vnd.usdz+zip"))

        let url = SupabaseConfig.publicURL(bucket: "uploads", path: path).absoluteString
        let now = ISO8601DateFormatter().string(from: Date())

        try await patchProject(projectId, [
            "scan_json": [
                "usdz_url": url,
                "provider": "roomplan",
                "saved_at": now
            ],
            "ar_provider": "roomplan"
        ])
    }

    // MARK: - Fetch
    func fetchProject(projectId: String) async throws -> Project {
        var comps = URLComponents(url: AppConfig.supabaseURL
            .appendingPathComponent("rest/v1/projects"), resolvingAgainstBaseURL: false)!
        comps.queryItems = [
            URLQueryItem(name: "id", value: "eq.\(projectId)"),
            URLQueryItem(name: "select", value: "*")
        ]

        var req = URLRequest(url: comps.url!)
        req.httpMethod = "GET"
        AppConfig.supabaseHeaders.forEach { req.setValue($1, forHTTPHeaderField: $0) }

        let (data, resp) = try await URLSession.shared.data(for: req)
        try Self.ensure2xx(resp, data: data, context: "Fetch project")

        let rows = try JSONDecoder().decode([Project].self, from: data)
        guard let first = rows.first else { throw Self.err("Project not found.") }
        return first
    }

    func fetchProjects() async throws -> [Project] {
        var comps = URLComponents(url: AppConfig.supabaseURL
            .appendingPathComponent("rest/v1/projects"), resolvingAgainstBaseURL: false)!
        comps.queryItems = [
            URLQueryItem(name: "user_id", value: "eq.\(userId)"),
            URLQueryItem(name: "order", value: "created_at.desc"),
            URLQueryItem(name: "select", value: "*")
        ]

        var req = URLRequest(url: comps.url!)
        req.httpMethod = "GET"
        AppConfig.supabaseHeaders.forEach { req.setValue($1, forHTTPHeaderField: $0) }

        let (data, resp) = try await URLSession.shared.data(for: req)
        try Self.ensure2xx(resp, data: data, context: "Fetch projects")
        return try JSONDecoder().decode([Project].self, from: data)
    }

    // MARK: - DIYGenie webhooks (preview / plan)
    @discardableResult
    func generatePreview(projectId: String) async throws -> String {
        let url = AppConfig.apiBaseURL.appendingPathComponent("api/projects/\(projectId)/preview")
        let (data, _) = try await postJSON(url, body: [:])   // <-- use data
        if let obj = try JSONSerialization.jsonObject(with: data) as? [String: Any],
           let previewURL = obj["preview_url"] as? String {
            return previewURL
        }
        return "" // ok if backend doesn't return a URL yet
    }

    func generatePlanOnly(projectId: String) async throws {
        let url = AppConfig.apiBaseURL.appendingPathComponent("api/projects/\(projectId)/plan")
        _ = try await postJSON(url, body: [:])               // fire-and-forget
    }

    // MARK: - Internal: PATCH project via REST
    private func patchProject(_ id: String, _ fields: [String: Any]) async throws {
        var comps = URLComponents(url: AppConfig.supabaseURL
            .appendingPathComponent("rest/v1/projects"), resolvingAgainstBaseURL: false)!
        comps.queryItems = [URLQueryItem(name: "id", value: "eq.\(id)")]

        var req = URLRequest(url: comps.url!)
        req.httpMethod = "PATCH"
        AppConfig.supabaseHeaders.forEach { req.setValue($1, forHTTPHeaderField: $0) }
        req.httpBody = try JSONSerialization.data(withJSONObject: fields, options: [])

        let (data, resp) = try await URLSession.shared.data(for: req)
        try Self.ensure2xx(resp, data: data, context: "Patch project")
    }

    // MARK: - HTTP helpers
    private static func ensure2xx(_ resp: URLResponse, data: Data, context: String) throws {
        guard let http = resp as? HTTPURLResponse, 200..<300 ~= http.statusCode else {
            let body = String(data: data, encoding: .utf8) ?? "<no body>"
            throw err("\(context) failed (\((resp as? HTTPURLResponse)?.statusCode ?? -1)): \(body)")
        }
    }

    private static func err(_ msg: String) -> NSError {
        NSError(domain: "ProjectsService", code: -1, userInfo: [NSLocalizedDescriptionKey: msg])
    }

    @discardableResult
    private func postJSON(_ url: URL, body: [String: Any]) async throws -> (Data, URLResponse) {
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
        let (data, resp) = try await URLSession.shared.data(for: req)
        try Self.ensure2xx(resp, data: data, context: "POST \(url.lastPathComponent)")
        return (data, resp)
    }
}

