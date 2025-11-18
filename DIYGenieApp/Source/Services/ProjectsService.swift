//
//  ProjectsService.swift
//  DIYGenieApp
//

import Foundation
import UIKit

struct ProjectsService {
    enum ServiceError: Error {
        case invalidResponse
        case decodeFailed
        case missingProject
        case unsupported
    }

    let userId: String
    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    init(userId: String, session: URLSession = .shared) {
        self.userId = userId
        self.session = session

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        self.decoder = decoder

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.keyEncodingStrategy = .convertToSnakeCase
        self.encoder = encoder
    }

    // MARK: - Create
    func createProject(name: String, goal: String, budget: String, skillLevel: String) async throws -> Project {
        // Normalize and harden the name so it always satisfies backend validation.
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedGoal = goal.trimmingCharacters(in: .whitespacesAndNewlines)

        let baseName: String
        if !trimmedName.isEmpty {
            baseName = trimmedName
        } else if !trimmedGoal.isEmpty {
            baseName = trimmedGoal
        } else {
            baseName = "DIY Project"
        }

        let safeName: String
        if baseName.count >= 10 {
            safeName = baseName
        } else {
            // Append a short suffix rather than padding with spaces so the final value
            // is always at least 10 characters even if the backend trims whitespace.
            safeName = baseName + " – DIY Genie"
        }

        // Ensure goal is always non-empty and normalized, similar to name
        let safeGoal: String
        if !trimmedGoal.isEmpty {
            safeGoal = trimmedGoal
        } else {
            // If the user doesn't type a goal, fall back to the safe name so the
            // backend always receives a meaningful, non-empty goal string.
            safeGoal = safeName
        }

        // Normalize skill level into the lowercase tokens expected by the backend.
        let normalizedSkill: String
        switch skillLevel.lowercased() {
        case "beginner":
            normalizedSkill = "beginner"
        case "intermediate":
            normalizedSkill = "intermediate"
        case "advanced":
            normalizedSkill = "advanced"
        default:
            normalizedSkill = "intermediate"
        }

        let payload = CreateProjectPayload(
            userId: userId,
            name: safeName,
            goal: safeGoal,
            budget: budget,
            skillLevel: normalizedSkill
        )

        var request = URLRequest(url: AppConfig.apiBaseURL.appendingPathComponent("api/projects"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try encoder.encode(payload)

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw ServiceError.invalidResponse
        }

        guard (200..<300).contains(http.statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? "<no body>"
            print("[ProjectsService] createProject failed with status \(http.statusCode). Body: \(body)")
            throw ServiceError.invalidResponse
        }

        let envelope = try decoder.decode(CreateProjectEnvelope.self, from: data)
        guard let id = envelope.projectId else {
            throw ServiceError.missingProject
        }

        // Fetch the full project record from Supabase so the app has a complete model.
        return try await fetchProject(projectId: id)
    }

    // MARK: - Fetch
    func fetchProjects() async throws -> [Project] {
        var components = URLComponents(url: supabaseRESTPath("projects"), resolvingAgainstBaseURL: false)!
        components.queryItems = [
            URLQueryItem(name: "select", value: "*"),
            URLQueryItem(name: "user_id", value: "eq.\(userId)"),
            URLQueryItem(name: "order", value: "updated_at.desc")
        ]

        let request = try supabaseRequest(url: components.url!, method: "GET")
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw ServiceError.invalidResponse
        }

        let records = try decoder.decode([SupabaseProjectRecord].self, from: data)
        return records.map { $0.toProject() }
    }

    func fetchProject(projectId: String) async throws -> Project {
        var components = URLComponents(url: supabaseRESTPath("projects"), resolvingAgainstBaseURL: false)!
        components.queryItems = [
            URLQueryItem(name: "select", value: "*"),
            URLQueryItem(name: "id", value: "eq.\(projectId)"),
            URLQueryItem(name: "limit", value: "1")
        ]

        let request = try supabaseRequest(url: components.url!, method: "GET")
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw ServiceError.invalidResponse
        }

        let records = try decoder.decode([SupabaseProjectRecord].self, from: data)
        guard let record = records.first else {
            throw ServiceError.missingProject
        }
        return record.toProject()
    }

    // MARK: - Uploads
    @discardableResult
    func uploadImage(projectId: String, image: UIImage) async throws -> Project {
        guard let jpeg = image.jpegData(compressionQuality: 0.85) else {
            throw ServiceError.decodeFailed
        }

        let boundary = "Boundary-\(UUID().uuidString)"
        var request = URLRequest(url: AppConfig.apiBaseURL.appendingPathComponent("api/projects/\(projectId)/image"))
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()
        body.appendMultipartField(name: "file", filename: "photo.jpg", mimeType: "image/jpeg", data: jpeg, boundary: boundary)
        body.appendString("--\(boundary)--\r\n")
        request.httpBody = body

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw ServiceError.invalidResponse
        }

        guard (200..<300).contains(http.statusCode) else {
            let bodyString = String(data: data, encoding: .utf8) ?? "<no body>"
            print("[ProjectsService] uploadImage failed with status \(http.statusCode). Body: \(bodyString)")
            throw ServiceError.invalidResponse
        }

        // Some environments return { ok: true }, others include URLs. Decode loosely.
        _ = try? decoder.decode(UploadPhotoEnvelope.self, from: data)
        return try await fetchProject(projectId: projectId)
    }

    func uploadARScan(projectId: String, fileURL: URL) async throws {
        // Upload the raw USDZ file to Supabase Storage.
        let fileData = try Data(contentsOf: fileURL)
        let path = "projects/\(projectId)/scans/\(UUID().uuidString).usdz"
        _ = try await uploadToStorage(bucket: "room-scans", path: path, data: fileData, contentType: "model/vnd.usdz+zip")

        // For now we stop here: the scan is stored and accessible via the public URL.
        // A future server-side update can attach this path into a dedicated room_scans table.
        let publicURL = AppConfig.publicURL(bucket: "room-scans", path: path)
        print("[ProjectsService] AR scan uploaded to:\n\(publicURL)")
    }

    // MARK: - Preview + Plan
    func generatePreview(projectId: String) async throws -> Project {
        // Call the new synchronous Decor8 preview endpoint on the backend.
        let url = AppConfig.apiBaseURL.appendingPathComponent("preview/decor8")

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Reuse the PreviewTriggerPayload so we send both projectId and project_id
        // and stay compatible with the backend contract.
        let payload = PreviewTriggerPayload(projectId: projectId)
        request.httpBody = try encoder.encode(payload)

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw ServiceError.invalidResponse
        }

        guard (200..<300).contains(http.statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? "<no body>"
            print("[ProjectsService] generatePreview /preview/decor8 failed with status \(http.statusCode). Body: \(body)")
            throw ServiceError.invalidResponse
        }

        // The backend already updates Supabase with preview_url and preview_status.
        // We can optionally try to decode the response, but we don't depend on it.
        struct PreviewDecor8Response: Decodable {
            let ok: Bool?
            let previewUrl: String?
        }
        _ = try? decoder.decode(PreviewDecor8Response.self, from: data)

        // Return the freshest project record, including preview_url / preview_status.
        return try await fetchProject(projectId: projectId)
    }

    @discardableResult
    func generatePlanOnly(projectId: String) async throws -> Project {
        let project = try await fetchProject(projectId: projectId)
        let photoURL = project.inputImageURL ?? project.previewURL
        let prompt = project.goal ?? project.name

        // Build the payload using the PlanTriggerPayload DTO so we always
        // emit both `photoUrl` and `photo_url` when an image is available.
        let trigger = PlanTriggerPayload(
            photoUrl: photoURL,
            prompt: prompt,
            measurements: nil
        )

        var planRequest = URLRequest(url: AppConfig.apiBaseURL.appendingPathComponent("plan"))
        planRequest.httpMethod = "POST"
        planRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        planRequest.httpBody = try encoder.encode(trigger)

        let (data, response) = try await session.data(for: planRequest)
        guard let http = response as? HTTPURLResponse else {
            throw ServiceError.invalidResponse
        }

        guard (200..<300).contains(http.statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? "<no body>"
            print("[ProjectsService] generatePlanOnly /plan failed with status \(http.statusCode). Body: \(body)")
            throw ServiceError.invalidResponse
        }

        let planEnvelope = try decoder.decode(PlanEnvelope.self, from: data)
        guard let plan = planEnvelope.plan else {
            throw ServiceError.decodeFailed
        }

        let update = PlanUpdatePayload(planJson: plan, status: "plan_ready")
        var updateRequest = try supabaseRequest(url: supabaseRESTPath("projects"), method: "PATCH", queryItems: [
            URLQueryItem(name: "id", value: "eq.\(projectId)"),
            URLQueryItem(name: "select", value: "*")
        ])
        updateRequest.httpBody = try encoder.encode(update)

        let (updateData, updateResponse) = try await session.data(for: updateRequest)
        guard let updateHTTP = updateResponse as? HTTPURLResponse else {
            throw ServiceError.invalidResponse
        }

        guard (200..<300).contains(updateHTTP.statusCode) else {
            let body = String(data: updateData, encoding: .utf8) ?? "<no body>"
            print("[ProjectsService] generatePlanOnly Supabase update failed with status \(updateHTTP.statusCode). Body: \(body)")
            throw ServiceError.invalidResponse
        }

        let updated = try decoder.decode([SupabaseProjectRecord].self, from: updateData)
        if let record = updated.first {
            return record.toProject()
        }

        return try await fetchProject(projectId: projectId)
    }

    func attachCropRectIfAvailable(projectId: String, rect: CGRect) async {
        let roi: [String: Any] = [
            "x": Double(rect.origin.x),
            "y": Double(rect.origin.y),
            "w": Double(rect.size.width),
            "h": Double(rect.size.height)
        ]

        let patch = SupabaseProjectUpdate(previewMeta: ["roi": AnyCodable(roi)])
        _ = try? await updateProject(id: projectId, patch: patch)
    }
}

// MARK: - Private helpers
private extension ProjectsService {
    func supabaseRESTPath(_ path: String) -> URL {
        AppConfig.supabaseURL.appendingPathComponent("rest/v1/").appendingPathComponent(path)
    }

    func supabaseRequest(url: URL, method: String, queryItems: [URLQueryItem]? = nil) throws -> URLRequest {
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)!
        if let q = queryItems, !q.isEmpty {
            components.queryItems = (components.queryItems ?? []) + q
        }

        guard let finalURL = components.url else {
            throw ServiceError.invalidResponse
        }

        var request = URLRequest(url: finalURL)
        request.httpMethod = method
        request.setValue(AppConfig.supabaseAnonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(AppConfig.supabaseAnonKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("return=representation", forHTTPHeaderField: "Prefer")
        return request
    }

    func updateProject(id: String, patch: SupabaseProjectUpdate) async throws -> SupabaseProjectRecord? {
        var request = try supabaseRequest(url: supabaseRESTPath("projects"), method: "PATCH", queryItems: [
            URLQueryItem(name: "id", value: "eq.\(id)"),
            URLQueryItem(name: "select", value: "*")
        ])
        request.httpBody = try encoder.encode(patch)

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            return nil
        }

        let records = try decoder.decode([SupabaseProjectRecord].self, from: data)
        return records.first
    }

    func uploadToStorage(bucket: String, path: String, data: Data, contentType: String) async throws -> String {
        var request = URLRequest(url: AppConfig.supabaseURL
            .appendingPathComponent("storage/v1/object")
            .appendingPathComponent(bucket)
            .appendingPathComponent(path))
        request.httpMethod = "POST"
        request.httpBody = data
        request.setValue(contentType, forHTTPHeaderField: "Content-Type")
        request.setValue("true", forHTTPHeaderField: "x-upsert")
        request.setValue(AppConfig.supabaseAnonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(AppConfig.supabaseAnonKey)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw ServiceError.invalidResponse
        }

        guard (200..<300).contains(http.statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? "<no body>"
            print("[ProjectsService] uploadToStorage failed with status \(http.statusCode). Body: \(body)")
            throw ServiceError.invalidResponse
        }

        return path
    }
}

// MARK: - DTOs

private struct SupabaseProjectInsert: Encodable {
    let userId: String
    let name: String
    let goal: String
    let budget: String
    let skillLevel: String?

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case name
        case goal
        case budget
        case skillLevel = "skill_level"
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(userId, forKey: .userId)
        try container.encode(name, forKey: .name)
        try container.encode(goal, forKey: .goal)
        try container.encode(budget, forKey: .budget)
        if let skillLevel {
            try container.encode(skillLevel, forKey: .skillLevel)
        }
    }
}

private struct CreateProjectPayload: Encodable {
    let userId: String
    let name: String
    let goal: String
    let budget: String
    let skillLevel: String
}

private struct CreateProjectEnvelope: Decodable {
    let ok: Bool?
    let item: CreateProjectItem?
    let id: String?

    var projectId: String? {
        if let id { return id }
        if let item { return item.id }
        return nil
    }
}

private struct CreateProjectItem: Decodable {
    let id: String
    let status: String?
}

private struct SupabaseProjectUpdate: Encodable {
    var goal: String?
    var skillLevel: String?
    var budget: String?
    var previewMeta: [String: AnyCodable]?

    enum CodingKeys: String, CodingKey {
        case goal
        case skillLevel = "skill_level"
        case budget
        case previewMeta = "preview_meta"
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        if let goal { try container.encode(goal, forKey: .goal) }
        if let skillLevel { try container.encode(skillLevel, forKey: .skillLevel) }
        if let budget { try container.encode(budget, forKey: .budget) }
        if let previewMeta { try container.encode(previewMeta, forKey: .previewMeta) }
    }
}

private struct UploadPhotoEnvelope: Decodable {
    let ok: Bool?
    let photoUrl: String?
}

private struct AttachScanPayload: Encodable {
    let roomplan: [String: AnyCodable]
}

private struct PreviewTriggerPayload: Encodable {
    let projectId: String

    private enum CodingKeys: String, CodingKey {
        case projectId      // "projectId"
        case project_id     // "project_id"
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        // Send both camelCase and snake_case so the backend can read whichever it expects.
        try container.encode(projectId, forKey: .projectId)
        try container.encode(projectId, forKey: .project_id)
    }
}

private struct PreviewStatusEnvelope: Decodable {
    let ok: Bool?
    let status: String
    let previewUrl: String?
}

private struct PlanTriggerPayload: Encodable {
    let photoUrl: String?
    let prompt: String
    let measurements: [String: AnyCodable]?

    private enum CodingKeys: String, CodingKey {
        case photoUrl       // "photoUrl"
        case photo_url      // "photo_url"
        case prompt
        case measurements
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        if let photoUrl {
            // Send both keys so a backend looking for "photo_url" is satisfied,
            // and any code using "photoUrl" still works.
            try container.encode(photoUrl, forKey: .photoUrl)
            try container.encode(photoUrl, forKey: .photo_url)
        }

        try container.encode(prompt, forKey: .prompt)
        if let measurements {
            try container.encode(measurements, forKey: .measurements)
        }
    }
}

private struct PlanEnvelope: Decodable {
    let ok: Bool?
    let plan: PlanResponse?
}

private struct PlanUpdatePayload: Encodable {
    let planJson: PlanResponse
    let status: String

    enum CodingKeys: String, CodingKey {
        case planJson = "plan_json"
        case status
    }
}

