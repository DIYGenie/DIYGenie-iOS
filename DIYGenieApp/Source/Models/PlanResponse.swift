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
}

struct OpenAIResponse: Codable {
    struct Choice: Codable {
        struct Message: Codable {
            let role: String
            let content: String
        }
        let message: Message
    }
    let choices: [Choice]
}
