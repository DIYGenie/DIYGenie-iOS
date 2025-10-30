//
//  ProjectsService.swift
//  DIYGenieApp
//
//  Created by Tye Kowalski on 10/30/25.
//

import Foundation
import Supabase
import UIKit

// MARK: - Helper Type
struct AnyEncodable: Encodable {
    private let encode: (Encoder) throws -> Void
    init<T: Encodable>(_ value: T) { self.encode = value.encode }
    func encode(to encoder: Encoder) throws { try encode(encoder) }
}

// MARK: - ProjectsService
struct ProjectsService {
    private let client: SupabaseClient
    private let userId: String

    init(userId: String) {
        self.userId = userId
        self.client = SupabaseConfig.client
    }

    // MARK: - Fetch All Projects (async)
    func fetchProjects() async throws -> [Project] {
        let response: [Project] = try await client
            .from("projects")
            .select()
            .eq("user_id", value: userId)
            .order("created_at", ascending: false)
            .execute()
            .value
        return response
    }

    // MARK: - Fetch AI Build Plan
    func fetchPlan(projectId: String) async throws -> PlanResponse {
        let response: [PlanResponse] = try await client
            .from("projects")
            .select("plan_text, steps, tools_and_materials, cost_estimate")
            .eq("id", value: projectId)
            .limit(1)
            .execute()
            .value

        guard let plan = response.first else {
            throw NSError(domain: "FetchPlanError", code: 0, userInfo: [NSLocalizedDescriptionKey: "No plan found for this project."])
        }

        return plan
    }

    // MARK: - Create Project
    func createProject(name: String, goal: String, budget: String, skillLevel: String) async throws -> Project {
        let insertData: [String: AnyEncodable] = [
            "user_id": AnyEncodable(userId),
            "name": AnyEncodable(name),
            "goal": AnyEncodable(goal),
            "budget": AnyEncodable(budget),
            "skill_level": AnyEncodable(skillLevel),
            "created_at": AnyEncodable(ISO8601DateFormatter().string(from: Date()))
        ]

        let response: Project = try await client
            .from("projects")
            .insert(insertData)
            .select()
            .single()
            .execute()
            .value

        return response
    }

    // MARK: - Upload Image to Supabase Storage
    func uploadImage(projectId: String, image: UIImage) async throws -> String {
        guard let imageData = image.jpegData(compressionQuality: 0.85) else {
            throw NSError(domain: "UploadError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to encode image"])
        }

        let fileName = "uploads/\(projectId)_original.jpg"
        _ = try await client.storage
            .from("uploads")
            .upload(fileName, data: imageData, options: FileOptions(contentType: "image/jpeg", upsert: true))

        // ✅ Convert to String before returning
        let publicURL = try client.storage.from("uploads").getPublicURL(path: fileName)
        try await client.from("projects")
            .update(["original_image_url": publicURL.absoluteString])
            .eq("id", value: projectId)
            .execute()

        return publicURL.absoluteString
    }

    // MARK: - Generate Decor8 AI Preview
    func generatePreview(projectId: String) async throws -> String {
        // 1️⃣ Fetch original image URL from Supabase
        let project: Project = try await client
            .from("projects")
            .select()
            .eq("id", value: projectId)
            .single()
            .execute()
            .value

        guard let originalURL = project.originalImageURL else {
            throw NSError(domain: "PreviewError", code: 0, userInfo: [NSLocalizedDescriptionKey: "No image URL found"])
        }

        // 2️⃣ Call Decor8 API
        guard let apiURL = URL(string: "https://api.decor8.ai/generate-preview") else {
            throw NSError(domain: "PreviewError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid Decor8 URL"])
        }

        var request = URLRequest(url: apiURL)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue(SupabaseConfig.decor8Key, forHTTPHeaderField: "Authorization")

        let body: [String: Any] = ["image_url": originalURL, "prompt": project.goal ?? "home improvement"]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw NSError(domain: "PreviewError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Decor8 request failed"])
        }

        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let previewURL = json?["preview_url"] as? String else {
            throw NSError(domain: "PreviewError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Missing preview_url in response"])
        }

        // 3️⃣ Save to Supabase
        try await client.from("projects")
            .update(["preview_image_url": previewURL])
            .eq("id", value: projectId)
            .execute()

        return previewURL
    }

    // MARK: - Generate Plan (text only)
    func generatePlanOnly(projectId: String) async throws -> String {
        let project: Project = try await client
            .from("projects")
            .select()
            .eq("id", value: projectId)
            .single()
            .execute()
            .value

        guard let goal = project.goal else { throw NSError(domain: "PlanError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Missing project goal"]) }

        // Call your OpenAI backend endpoint
        guard let apiURL = URL(string: "https://api.diygenieapp.com/generate-plan") else {
            throw NSError(domain: "PlanError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid API URL"])
        }

        var request = URLRequest(url: apiURL)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: ["project_id": projectId, "goal": goal])

        let (data, _) = try await URLSession.shared.data(for: request)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let planText = json?["plan_text"] as? String ?? "No plan generated."

        // Save to Supabase
        try await client.from("projects")
            .update(["plan_text": planText])
            .eq("id", value: projectId)
            .execute()

        return planText
    }

    // MARK: - Update Project
    func updateProject(projectId: String, fields: [String: AnyEncodable]) async throws -> Project {
        let response: Project = try await client
            .from("projects")
            .update(fields)
            .eq("id", value: projectId)
            .select()
            .single()
            .execute()
            .value
        return response
    }

    // MARK: - Delete Project
    func deleteProject(projectId: String) async throws {
        _ = try await client.from("projects").delete().eq("id", value: projectId).execute()
    }
}

