//
//  PlanResponse.swift
//  DIYGenieApp
//
//  Unified response for Decor8 (visual) + OpenAI (text-based) plans
//  Updated: 2025-11-01
//

import Foundation

struct PlanResponse: Codable {
    let project_id: String?
    let summary: String?
    let cost_estimate: CostEstimate?
    let materials: [MaterialItem]?
    let tools: [ToolItem]?
    let steps: [StepItem]?
    let decor8_preview_url: String?
    let decor8_before_url: String?
    let decor8_after_url: String?
    let created_at: String?
    let ai_model: String?
    let version: String?

    // Safe decoding from possibly incomplete JSON
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        project_id = try? container.decodeIfPresent(String.self, forKey: .project_id)
        summary = try? container.decodeIfPresent(String.self, forKey: .summary)
        cost_estimate = try? container.decodeIfPresent(CostEstimate.self, forKey: .cost_estimate)
        materials = try? container.decodeIfPresent([MaterialItem].self, forKey: .materials)
        tools = try? container.decodeIfPresent([ToolItem].self, forKey: .tools)
        steps = try? container.decodeIfPresent([StepItem].self, forKey: .steps)
        decor8_preview_url = try? container.decodeIfPresent(String.self, forKey: .decor8_preview_url)
        decor8_before_url = try? container.decodeIfPresent(String.self, forKey: .decor8_before_url)
        decor8_after_url = try? container.decodeIfPresent(String.self, forKey: .decor8_after_url)
        created_at = try? container.decodeIfPresent(String.self, forKey: .created_at)
        ai_model = try? container.decodeIfPresent(String.self, forKey: .ai_model)
        version = try? container.decodeIfPresent(String.self, forKey: .version)
    }
}

// MARK: - Supporting Types
struct CostEstimate: Codable {
    let total: Double?
    let currency: String?
    let breakdown: [String: Double]?
}

struct MaterialItem: Codable {
    let name: String
    let quantity: String?
    let notes: String?
}

struct ToolItem: Codable {
    let name: String
    let required: Bool?
}

struct StepItem: Codable {
    let index: Int?
    let title: String?
    let instructions: String?
    let estimated_minutes: Int?
}

