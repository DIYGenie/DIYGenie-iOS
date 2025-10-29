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

    // MARK: - Fetch projects
    func fetchProjects() async throws -> [Project] {
        let response = try await client.database
            .from("projects")
            .select()
            .eq("user_id", value: userId)
            .execute()
        return try response.decoded(to: [Project].self)
    }

    // MARK: - Update
    func updateProject(_ project: Project) async throws {
        try await client.database
            .from("projects")
            .update(values: [
                "preview_url": project.previewURL ?? "",
                "input_image_url": project.inputImageURL ?? "",
                "output_image_url": project.outputImageURL ?? ""
            ])
            .eq("id", value: project.id)
            .execute()
    }
}
// MARK: - Fetch plan (build plan details)
func fetchPlan(projectId: String) async throws -> PlanResponse {
    let url = URL(string: "\(SupabaseConfig.baseURL)/api/plan/\(projectId)")!
    var request = URLRequest(url: url)
    request.httpMethod = "GET"
    
    let (data, response) = try await URLSession.shared.data(for: request)
    guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
        throw URLError(.badServerResponse)
    }
    return try JSONDecoder().decode(PlanResponse.self, from: data)
}
