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
}
