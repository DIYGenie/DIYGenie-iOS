//
//  ProjectsService.swift
//  DIYGenieApp
//
//  Created by Tye Kowalski on 10/30/25.
//

import Foundation
import Supabase
import Foundation
import Supabase

// MARK: - Helper Type
struct AnyEncodable: Encodable {
    private let encode: (Encoder) throws -> Void

    init<T: Encodable>(_ value: T) {
        self.encode = value.encode
    }

    func encode(to encoder: Encoder) throws {
        try encode(encoder)
    }
}
struct ProjectsService {
    private let client: SupabaseClient
    private let userId: String
    
    init(userId: String) {
        self.userId = userId
        self.client = SupabaseConfig.client
    }
    
    // MARK: - Fetch Projects
    func fetchProjects(completion: @escaping (Result<[Project], Error>) -> Void) {
        Task {
            do {
                let response: [Project] = try await client
                    .from("projects")
                    .select()
                    .eq("user_id", value: userId)
                    .order("created_at", ascending: false)
                    .execute()
                    .value
                
                completion(.success(response))
            } catch {
                completion(.failure(error))
            }
        }
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
}
