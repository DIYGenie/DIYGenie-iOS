//
//  Project.swift
//  DIYGenieApp
//

import Foundation

struct Project: Codable, Identifiable {
    let id: String
    let userId: String
    let name: String?
    let goal: String?
    let budget: String?
    let skillLevel: String?
    let originalImageURL: String?
    let previewURL: String?
    let aiPlan: String?
    let createdAt: String?
}

