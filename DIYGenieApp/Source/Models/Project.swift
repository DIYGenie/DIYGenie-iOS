//
//  Project.swift
//  DIYGenieApp
//

import Foundation

struct Project: Codable, Identifiable {
    let id: String
    let user_id: String?
    let name: String?
    let goal: String?
    let budget: String?
    let skill_level: String?
    let plan_text: String?
    let created_at: String?
    let original_image_url: String?
    let preview_image_url: String?

    // MARK: - Swift-safe computed properties
    var originalImageURL: String? { original_image_url }
    var previewImageURL: String? { preview_image_url }
}

