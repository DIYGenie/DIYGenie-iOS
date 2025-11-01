//
//  PlanResponse.swift
//  DIYGenieApp
//

import Foundation

struct PlanResponse: Codable, Equatable {
    let summary: String?
    let steps: [Step]?
    let materials: [Material]?
    let tools: [String]?
    let estimated_cost: String?
    let preview_url: String?

    struct Step: Codable, Equatable {
        let title: String
        let description: String
        let image_url: String?
    }

    struct Material: Codable, Equatable {
        let name: String
        let quantity: String?
        let cost: String?
    }
}

