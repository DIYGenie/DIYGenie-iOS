import Foundation
import Supabase

final class ProjectsService {
    static let shared = ProjectsService()

    private let client: SupabaseClient

    private init() {
        guard
            let urlString = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_URL") as? String,
            let key = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_ANON_KEY") as? String,
            let url = URL(string: urlString)
        else {
            fatalError("❌ Missing Supabase credentials in Info.plist")
        }

        client = SupabaseClient(supabaseURL: url, supabaseKey: key)
    }

    func fetchProjects(for userId: String) async throws -> [Project] {
        let response = try await client
            .from("projects")
            .select()
            .eq("user_id", value: userId)
            .execute()

        let data = response.data
        return try JSONDecoder().decode([Project].self, from: data)
    }


    func createProject(_ project: Project) async throws {
        _ = try await client
            .from("projects")
            .insert(project)
            .execute()
    }
}
