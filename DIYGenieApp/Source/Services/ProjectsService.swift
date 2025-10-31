//
//  ProjectsService.swift
//  DIYGenieApp
//

import Foundation
import Supabase
import UIKit

struct ProjectsService {
    private let userId: String
    private let client = SupabaseConfig.client

    init(userId: String) {
        self.userId = userId
    }

    // MARK: - Fetch Projects
    func fetchProjects() async throws -> [Project] {
        let response = try await client
            .from("projects")
            .select()
            .eq("user_id", value: userId)
            .order("created_at", ascending: false)
            .execute()

        guard let resultData = response.data else {
            throw NSError(domain: "ProjectsService", code: 0, userInfo: [NSLocalizedDescriptionKey: "No data returned"])
        }

        let jsonData = try JSONSerialization.data(withJSONObject: resultData)
        return try JSONDecoder().decode([Project].self, from: jsonData)
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

        let response = try await client
            .from("projects")
            .insert(insertData) // ✅ correct Supabase v2+ syntax
            .select()
            .single()
            .execute()

        guard let resultData = response.data else {
            throw NSError(domain: "ProjectsService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Create project failed"])
        }

        let jsonData = try JSONSerialization.data(withJSONObject: resultData)
        return try JSONDecoder().decode(Project.self, from: jsonData)
    }

    // MARK: - Upload Image to Supabase Storage
    func uploadImage(projectId: String, image: UIImage) async throws {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw NSError(domain: "ProjectsService", code: 2, userInfo: [NSLocalizedDescriptionKey: "Invalid image data"])
        }

        let path = "\(userId)/\(UUID().uuidString).jpg"
        let bucket = client.storage.from("uploads")

        // ✅ Correct Supabase v2+ upload syntax
        _ = try await bucket.upload(path, data: imageData, options: FileOptions(contentType: "image/jpeg"))

        guard let publicURL = bucket.getPublicURL(path: path) else {
            throw NSError(domain: "ProjectsService", code: 3, userInfo: [NSLocalizedDescriptionKey: "Failed to get public URL"])
        }

        _ = try await client
            .from("projects")
            .update(["original_image_url": publicURL.absoluteString])
            .eq("id", value: projectId)
            .execute()
    }

    // MARK: - Generate Decor8 AI Preview
    func generatePreview(projectId: String) async throws -> URL {
        let response = try await client
            .from("projects")
            .select()
            .eq("id", value: projectId)
            .single()
            .execute()

        guard let resultData = response.data else {
            throw NSError(domain: "ProjectsService", code: 4, userInfo: [NSLocalizedDescriptionKey: "No project found"])
        }

        let jsonData = try JSONSerialization.data(withJSONObject: resultData)
        let project = try JSONDecoder().decode(Project.self, from: jsonData)

        guard let imageURL = project.originalImageURL,
              let goal = project.goal else {
            throw NSError(domain: "ProjectsService", code: 5, userInfo: [NSLocalizedDescriptionKey: "Missing image or goal"])
        }

        // ✅ Decor8 API call
        let endpoint = URL(string: "https://api.decor8.ai/generate-preview")!
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(SupabaseConfig.decor8Key)", forHTTPHeaderField: "Authorization")

        let body: [String: Any] = [
            "image_url": imageURL,
            "prompt": goal
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, responseHTTP) = try await URLSession.shared.data(for: request)
        guard let http = responseHTTP as? HTTPURLResponse,
              (200..<300).contains(http.statusCode) else {
            throw NSError(domain: "ProjectsService", code: 6, userInfo: [NSLocalizedDescriptionKey: "Decor8 API error"])
        }

        guard
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
            let previewURLString = json["preview_url"] as? String,
            let previewURL = URL(string: previewURLString)
        else {
            throw NSError(domain: "ProjectsService", code: 7, userInfo: [NSLocalizedDescriptionKey: "Invalid preview response"])
        }

        _ = try await client
            .from("projects")
            .update(["preview_url": previewURLString])
            .eq("id", value: projectId)
            .execute()

        return previewURL
    }

    // MARK: - Generate OpenAI Plan
    func generatePlanOnly(projectId: String) async throws -> PlanResponse {
        let response = try await client
            .from("projects")
            .select()
            .eq("id", value: projectId)
            .single()
            .execute()

        guard let resultData = response.data else {
            throw NSError(domain: "ProjectsService", code: 8, userInfo: [NSLocalizedDescriptionKey: "No project found"])
        }

        let jsonData = try JSONSerialization.data(withJSONObject: resultData)
        let project = try JSONDecoder().decode(Project.self, from: jsonData)
        guard let goal = project.goal else {
            throw NSError(domain: "ProjectsService", code: 9, userInfo: [NSLocalizedDescriptionKey: "Missing goal"])
        }

        let prompt = """
        Create a detailed DIY project plan for: "\(goal)".
        Include:
        - Step-by-step instructions
        - Tools list
        - Materials list
        - Estimated cost
        """

        // ✅ OpenAI API call
        let endpoint = URL(string: "https://api.openai.com/v1/chat/completions")!
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.addValue("Bearer \(SupabaseConfig.openAIKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "model": "gpt-4o-mini",
            "messages": [["role": "user", "content": prompt]]
        ])

        let (data, responseHTTP) = try await URLSession.shared.data(for: request)
        guard let http = responseHTTP as? HTTPURLResponse,
              (200..<300).contains(http.statusCode) else {
            throw NSError(domain: "ProjectsService", code: 10, userInfo: [NSLocalizedDescriptionKey: "OpenAI request failed"])
        }

        let decoded = try JSONDecoder().decode(OpenAIResponse.self, from: data)
        let planText = decoded.choices.first?.message.content ?? "No plan generated."

        _ = try await client
            .from("projects")
            .update(["ai_plan": planText])
            .eq("id", value: projectId)
            .execute()

        return PlanResponse(
            id: UUID().uuidString,
            title: project.name ?? "DIY Project Plan",
            description: goal,
            summary: planText,
            steps: nil,
            tools: nil,
            materials: nil,
            estimatedCost: nil
        )
    }

    // MARK: - Compatibility Wrapper for old views
    func fetchPlan(projectId: String) async throws -> PlanResponse {
        return try await generatePlanOnly(projectId: projectId)
    }
}

// MARK: - Helper Encodable Wrapper
struct AnyEncodable: Encodable {
    private let encodeFunc: (Encoder) throws -> Void
    init<T: Encodable>(_ value: T) { encodeFunc = value.encode }
    func encode(to encoder: Encoder) throws { try encodeFunc(encoder) }
}

