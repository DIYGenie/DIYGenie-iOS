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
    let input_image_url: String?
    let preview_url: String?
    let created_at: String?
}
