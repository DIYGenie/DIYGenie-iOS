//
//  Project.swift
//  DIYGenieApp
//

import Foundation

struct Project: Codable, Identifiable {
    let id: String
    let user_id: String
    let name: String
    let goal: String
    let budget: String
    let skill_level: String

    // Optional image + preview URLs
    let input_image_url: String?
    let preview_url: String?

    // Timestamps
    let created_at: String?

    // MARK: - Coding Keys for Supabase
    enum CodingKeys: String, CodingKey {
        case id
        case user_id
        case name
        case goal
        case budget
        case skill_level
        case input_image_url
        case preview_url
        case created_at
    }
}

