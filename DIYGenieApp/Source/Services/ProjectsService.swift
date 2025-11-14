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
        let payload = CreateProjectPayload(
            userId: userId,
            name: name,
            goal: goal,
            budget: budget,
            skillLevel: skillLevel
        )

        let url = AppConfig.apiBaseURL.appendingPathComponent("api/projects")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try encoder.encode(payload)

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw ServiceError.invalidResponse
        }

        let createEnvelope = try decoder.decode(CreateProjectEnvelope.self, from: data)
        guard let id = createEnvelope.projectId else {
            throw ServiceError.decodeFailed
        }

        // Ensure goal/skill level fields are persisted for downstream services.
        let patch = SupabaseProjectUpdate(goal: goal, skillLevel: skillLevel, budget: budget)
        _ = try await updateProject(id: id, patch: patch)

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
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw ServiceError.invalidResponse
        }

        // Some environments return { ok: true }, others include URLs. Decode loosely.
        _ = try? decoder.decode(UploadPhotoEnvelope.self, from: data)
        return try await fetchProject(projectId: projectId)
    }

    func uploadARScan(projectId: String, fileURL: URL) async throws {
        let data = try Data(contentsOf: fileURL)
        let path = "projects/\(projectId)/scans/\(UUID().uuidString).usdz"
        _ = try await uploadToStorage(bucket: "room-scans", path: path, data: data, contentType: "model/vnd.usdz+zip")

        let publicURL = AppConfig.publicURL(bucket: "room-scans", path: path)
        let payload = AttachScanPayload(roomplan: ["file_url": AnyCodable(publicURL)])

        var request = URLRequest(url: AppConfig.apiBaseURL.appendingPathComponent("api/projects/\(projectId)/scan"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try encoder.encode(payload)

        let (_, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw ServiceError.invalidResponse
        }
    }

    // MARK: - Preview + Plan
    func generatePreview(projectId: String) async throws -> Project {
        // Trigger Decor8 job
        var triggerRequest = URLRequest(url: AppConfig.apiBaseURL.appendingPathComponent("preview/decor8"))
        triggerRequest.httpMethod = "POST"
        triggerRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        triggerRequest.httpBody = try encoder.encode(PreviewTriggerPayload(projectId: projectId))

        let (_, triggerResponse) = try await session.data(for: triggerRequest)
        guard let triggerHTTP = triggerResponse as? HTTPURLResponse, (200..<300).contains(triggerHTTP.statusCode) else {
            throw ServiceError.invalidResponse
        }

        // Poll status a few times (stub returns instantly, live may take a few seconds)
        for attempt in 0..<8 {
            try await Task.sleep(nanoseconds: UInt64(0.75 * Double(NSEC_PER_SEC)))
            var components = URLComponents(url: AppConfig.apiBaseURL.appendingPathComponent("preview/status/\(projectId)"), resolvingAgainstBaseURL: false)!
            let statusRequest = URLRequest(url: components.url!)
            let (data, response) = try await session.data(for: statusRequest)
            guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
                continue
            }

            if let status = try? decoder.decode(PreviewStatusEnvelope.self, from: data), status.status.lowercased() == "ready" {
                // Fetch updated project and ensure plan exists.
                let project = try await fetchProject(projectId: projectId)
                if project.planJson == nil {
                    return try await generatePlanOnly(projectId: projectId)
                }
                return project
            }

            if attempt == 7 {
                break
            }
        }

        return try await fetchProject(projectId: projectId)
    }

    @discardableResult
    func generatePlanOnly(projectId: String) async throws -> Project {
        let project = try await fetchProject(projectId: projectId)
        let photoURL = project.inputImageURL ?? project.previewURL
        let payload = PlanTriggerPayload(photoUrl: photoURL, prompt: project.goal ?? project.name, measurements: project.dimensionsJson)

        var planRequest = URLRequest(url: AppConfig.apiBaseURL.appendingPathComponent("plan"))
        planRequest.httpMethod = "POST"
        planRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        planRequest.httpBody = try encoder.encode(payload)

        let (data, response) = try await session.data(for: planRequest)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
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
        guard let updateHTTP = updateResponse as? HTTPURLResponse, (200..<300).contains(updateHTTP.statusCode) else {
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

        let (_, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw ServiceError.invalidResponse
        }

        return path
    }
}

// MARK: - DTOs
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
