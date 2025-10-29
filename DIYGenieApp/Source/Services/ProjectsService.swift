//
//  ProjectsService.swift
//  DIYGenieApp
//

import Foundation
import Supabase

final class ProjectsService {
    private let client: SupabaseClient
    private let userId: String

    // MARK: - Init
    public init(userId: String) {
        self.userId = userId
        self.client = SupabaseClient(
            supabaseURL: URL(string: SupabaseConfig.url)!,
            supabaseKey: SupabaseConfig.key
        )
    }

    // MARK: - Fetch all projects
    func fetchProjects() async throws -> [Project] {
        let response: [Project] = try await client
            .from("projects")
            .select()
            .eq("user_id", value: userId)
            .execute()
            .value

        return response
    }

    // MARK: - Update project
    func updateProject(_ project: Project) async throws {
        _ = try await client
            .from("projects")
            .update([
                "preview_url": project.previewURL ?? "",
                "input_image_url": project.inputImageURL ?? "",
                "output_image_url": project.outputImageURL ?? ""
            ])
            .eq("id", value: project.id)
            .execute()
    }

    // MARK: - Fetch build plan (from DIY Genie backend)
    func fetchPlan(projectId: String) async throws -> PlanResponse {
        guard let url = URL(string: "\(SupabaseConfig.baseURL)/api/plan/\(projectId)") else {
            throw URLError(.badURL)
        }
        let (data, response) = try await URLSession.shared.data(from: url)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
        return try JSONDecoder().decode(PlanResponse.self, from: data)
    }
}
