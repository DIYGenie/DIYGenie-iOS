//
//  PlanResponse.swift
//  DIYGenieApp
//

import Foundation

struct PlanResponse: Codable, Identifiable {
    var id: String
    var title: String?
    var description: String?
    var summary: String?          // ✅ Added this line
    var steps: [String]?
    var tools: [String]?
    var materials: [String]?
    var estimatedCost: Double?
}
