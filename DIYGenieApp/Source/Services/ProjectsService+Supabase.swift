import Foundation
import UIKit

// IMPORTANT: there must be exactly ONE 'enum ProjectsService { }' somewhere else.
// This file is ONLY an extension. If you had copied an entire enum here, delete it.
extension ProjectsService {

    // MARK: - Create project (PostgREST)
    /// Inserts a row into `projects` (columns must match your table)
    static func createProject(
        name: String,
        goal: String,
        budget: String,
        skillLevel: String,
        userId: String,
        photoURL: URL?
    ) async throws -> String {
        struct Insert: Codable {
            let name: String
            let goal: String
            let budget: String
            let skill_level: String
            let user_id: String
            let photo_url: String?
        }
        struct Row: Codable { let id: String }

        let body = Insert(
            name: name,
            goal: goal,
            budget: budget,
            skill_level: skillLevel,
            user_id: userId,
            photo_url: photoURL?.absoluteString
        )

        var req = URLRequest(
            url: AppConfig.supabaseURL
                .appendingPathComponent("rest/v1/projects")
        )
        req.httpMethod = "POST"
        AppConfig.supabaseHeaders.forEach { req.setValue($1, forHTTPHeaderField: $0) }

        req.setValue("return=representation", forHTTPHeaderField: "Prefer")
        req.httpBody = try JSONEncoder().encode(body)

        let (data, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw NSError(domain: "ProjectsService", code: (resp as? HTTPURLResponse)?.statusCode ?? -1,
                          userInfo: [NSLocalizedDescriptionKey: "Create failed: \(String(data: data, encoding: .utf8) ?? "")"])
        }

        // PostgREST returns an array with the inserted row when using Prefer:return=representation
        let rows = try JSONDecoder().decode([Row].self, from: data)
        guard let id = rows.first?.id else { throw NSError(domain: "ProjectsService", code: -2, userInfo: [NSLocalizedDescriptionKey: "Missing id"]) }
        return id
    }

    // MARK: - Upload a photo to Supabase Storage (public bucket: 'uploads')
    /// Returns the public URL to the uploaded image
    static func uploadPhoto(_ image: UIImage) async throws -> URL {
        guard let jpeg = image.jpegData(compressionQuality: 0.9) else {
            throw NSError(domain: "ProjectsService", code: -10, userInfo: [NSLocalizedDescriptionKey: "Could not make JPEG"])
        }

        let fileName = "\(UUID().uuidString).jpg"
        var req = URLRequest(
            url: AppConfig.supabaseURL
                .appendingPathComponent("storage/v1/object/uploads/\(fileName)")
        )
        req.httpMethod = "POST"
        req.setValue(AppConfig.supabaseAnonKey, forHTTPHeaderField: "apikey")
        req.setValue("Bearer \(AppConfig.supabaseAnonKey)", forHTTPHeaderField: "Authorization")
        req.setValue("image/jpeg", forHTTPHeaderField: "Content-Type")
        req.httpBody = jpeg

        let (_, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw NSError(domain: "ProjectsService", code: (resp as? HTTPURLResponse)?.statusCode ?? -1,
                          userInfo: [NSLocalizedDescriptionKey: "Storage upload failed"])
        }

        // Public URL (assuming bucket 'uploads' is public)
        return AppConfig.supabaseURL
            .appendingPathComponent("storage/v1/object/public/uploads/\(fileName)")
    }

    // MARK: - Patch project with photo_url (optional helper)
    static func attachPhoto(to projectId: String, url: URL) async throws {
        struct Update: Codable { let photo_url: String }
        var req = URLRequest(
            url: AppConfig.supabaseURL
                .appendingPathComponent("rest/v1/projects")
                .appending("id", equals: "eq.\(projectId)") // ?id=eq.<uuid>
        )
        req.httpMethod = "PATCH"
        AppConfig.supabaseHeaders.forEach { req.setValue($1, forHTTPHeaderField: $0) }
        req.httpBody = try JSONEncoder().encode(Update(photo_url: url.absoluteString))

        let (_, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw NSError(domain: "ProjectsService", code: (resp as? HTTPURLResponse)?.statusCode ?? -1,
                          userInfo: [NSLocalizedDescriptionKey: "Attach photo failed"])
        }
    }

    // MARK: - Trigger Decor8 preview via your API
    /// POST https://api.diygenieapp.com/api/projects/:id/preview  → { "preview_url": "..." }
    static func generatePreview(projectId: String) async throws -> String {
        let url = AppConfig.apiBaseURL
            .appendingPathComponent("api/projects/\(projectId)/preview")

        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = Data("{}".utf8)

        let (data, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw NSError(domain: "ProjectsService", code: (resp as? HTTPURLResponse)?.statusCode ?? -1,
                          userInfo: [NSLocalizedDescriptionKey: "Preview failed: \(String(data: data, encoding: .utf8) ?? "")"])
        }

        let obj = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let previewURL = obj?["preview_url"] as? String, !previewURL.isEmpty else {
            throw NSError(domain: "ProjectsService", code: -3, userInfo: [NSLocalizedDescriptionKey: "preview_url missing"])
        }
        return previewURL
    }
}

// MARK: - tiny URL helper (avoids 'ambiguous' compiler error when adding query)
private extension URL {
    func appending(_ name: String, equals value: String) -> URL {
        var comps = URLComponents(url: self, resolvingAgainstBaseURL: false) ?? URLComponents()
        var items = comps.queryItems ?? []
        items.append(URLQueryItem(name: name, value: value))
        comps.queryItems = items
        return comps.url ?? self
    }
}

