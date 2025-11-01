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
    let status: String?
    let created_at: String?
    let photo_url: String?
    let ar_scan_url: String?
    let plan_url: String?
    let preview_url: String?
    let plan_summary: String?
    let plan_steps: [String]?

    enum CodingKeys: String, CodingKey {
        case id
        case user_id
        case name
        case goal
        case budget
        case skill_level
        case status
        case created_at
        case photo_url
        case ar_scan_url
        case plan_url
        case preview_url
        case plan_summary
        case plan_steps
    }
}

