//
//  PlanResponse.swift
//  DIYGenieApp
//

import Foundation

struct PlanResponse: Codable, Identifiable {
    let id: String
    let title: String?
    let description: String?
    let summary: String?
    let steps: [String]?
    let tools: [String]?
    let materials: [String]?
    let estimatedCost: Double?

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case description
        case summary
        case steps
        case tools
        case materials
        case estimatedCost
    }
}

