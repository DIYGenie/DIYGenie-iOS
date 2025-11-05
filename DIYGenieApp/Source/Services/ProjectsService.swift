//
//  ProjectsService.swift
//  DIYGenieApp
//

import Foundation
import UIKit
import Supabase

struct ProjectsService {

    // MARK: - Dependencies (fixes 'client' / 'userId' not in scope)
    let userId: String
    let client: SupabaseClient

    init(userId: String, client: SupabaseClient = SupabaseConfig.client) {
        self.userId = userId
        self.client = client
    }

    // MARK: - Plan (server) → full plan JSON
    func generatePlanOnly(projectId: String) async throws -> PlanResponse {
        // Build strict base URL from Info.plist
        let base = API.baseURL
        let url = try requireURL_(base: base)
            .appendingPathComponent("api")
            .appendingPathComponent("projects")
            .appendingPathComponent(projectId)
            .appendingPathComponent("generate-plan")

        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let (data, response) = try await URLSession.shared.data(for: req)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw NSError(domain: "ProjectsService", code: http.statusCode, userInfo: [
                NSLocalizedDescriptionKey: "Plan failed: \(body)"
            ])
        }

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(PlanResponse.self, from: data)
    }

    // MARK: - Fetch projects for signed-in user
    func fetchProjects() async throws -> [Project] {
        // Supabase Swift decodes directly when the generic is specified.
        let response: PostgrestResponse<[Project]> = try await client
            .from("projects")
            .select()
            .eq("user_id", value: userId)
            .order("created_at", ascending: false)
            .execute()
        return response.value
    }

    // MARK: - Strict URL helper
    private func requireURL_(base: String) throws -> URL {
        if let url = URL(string: base) { return url }
        throw NSError(domain: "ProjectsService", code: -99,
                      userInfo: [NSLocalizedDescriptionKey: "Invalid API_BASE_URL"])
    }
}
