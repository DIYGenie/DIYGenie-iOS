//
//  ProjectsService.swift
//  DIYGenieApp
//

import Foundation
import Supabase

final class ProjectsService {
    static let shared = ProjectsService(userId: "temp") // Replace with real user ID dynamically if needed

    private let client: SupabaseClient
    private let userId: String

    // MARK: - Init
    init(userId: String) {
        self.userId = userId
        self.client = SupabaseClient(
            supabaseURL: URL(string: SupabaseConfig.url)!,
            supabaseKey: SupabaseConfig.key
        )
    }

    // MARK: - Create Project
    struct NewProject: Encodable {
        let name: String
        let goal: String
        let budget: String
        let skill_level: String
        let input_image_url: String
        let user_id: String
    }

    func createProject(
        name: String,
        goal: String,
        budget: String,
        skillLevel: String,
        imagePath: String
    ) async throws -> String {
        let newProject = NewProject(
            name: name,
            goal: goal,
            budget: budget,
            skill_level: skillLevel,
            input_image_url: imagePath,
            user_id: userId
        )

        let response = try await client
            .from("projects")
            .insert(newProject)
            .select("id")
            .single()
            .execute()

        struct InsertResponse: Codable { let id: String }
        let decoded = try JSONDecoder().decode(InsertResponse.self, from: response.data)
        return decoded.id
    }

    // MARK: - Fetch All Projects
    func fetchProjects() async throws -> [Project] {
        let response = try await client
            .from("projects")
            .select()
            .eq("user_id", value: userId)
            .execute()

        return try JSONDecoder().decode([Project].self, from: response.data)
    }
}
// MARK: - Fetch Single Plan
struct PlanResponse: Codable {
    let id: String
    let project_id: String?
    let tools: [String]?
    let materials: [String]?
    let steps: [String]?
    let estimatedCost: Double?
    let created_at: String?
}

extension ProjectsService {
    func fetchPlan(projectId: String) async throws -> PlanResponse {
        // Adjust endpoint if using your webhook API instead of Supabase directly:
        // Example: https://api.diygenieapp.com/api/plans/:id
        let response = try await client
            .from("plans")
            .select()
            .eq("project_id", value: projectId)
            .single()
            .execute()

        return try JSONDecoder().decode(PlanResponse.self, from: response.data)
    }
}
