//
//  Project.swift
//  DIYGenieApp
//

import Foundation

struct Project: Codable, Identifiable, Hashable {
    let id: String
    let user_id: String
    let name: String
    let goal: String?
    let budget_tier: String?
    let skill_level: String?
    let status: String
    let created_at: String
    let updated_at: String?
    let preview_url: String?
    let input_image_url: String?
    let plan_json: PlanResponse?
    let preview_status: String?
    let is_demo: Bool?
    let budget: String?
    let completed_steps: [Int]?
    let current_step_index: Int?

    // MARK: - Computed helpers for SwiftUI convenience
    var previewURL: String? { preview_url }
    var inputImageURL: String? { input_image_url }

    var formattedDate: String {
        ISO8601DateFormatter().date(from: created_at)?
            .formatted(date: .abbreviated, time: .omitted) ?? ""
    }

    // MARK: - Coding keys match Supabase columns
    enum CodingKeys: String, CodingKey {
        case id, user_id, name, goal, budget_tier, skill_level, status,
             created_at, updated_at, preview_url, input_image_url,
             plan_json, preview_status, is_demo, budget,
             completed_steps, current_step_index
    }

    // MARK: - Manual Hashable + Equatable
    static func == (lhs: Project, rhs: Project) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}
