//
//  SupabasePreviewPassRecord.swift
//  DIYGenieApp
//

import Foundation

struct SupabasePreviewPassRecord: Codable {
    let id: String
    let projectId: String
    let status: String?
    let previewUrl: String?
    let planJson: PlanResponse?
    let createdAt: String?
    let updatedAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case projectId = "project_id"
        case status
        case previewUrl = "preview_url"
        case planJson = "plan_json"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}
