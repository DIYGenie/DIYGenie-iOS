import Foundation

struct Project: Codable, Identifiable, Hashable {
    let id: UUID
    let name: String
    let goal: String
    let user_id: UUID
    let created_at: Date
}

struct PlanCost: Codable, Hashable {
    let total: Double
    let currency: String
}

struct PlanMaterial: Codable, Hashable {
    let name: String?
    let qty: Double?
    let unit: String?
}

struct PlanStep: Codable, Identifiable, Hashable {
    let id: UUID = .init()
    let title: String?
    let detail: String?
}

struct Plan: Codable, Hashable {
    let steps: [PlanStep]
    let tools: [String]
    let materials: [PlanMaterial]
    let cost_estimate: PlanCost
    let updated_at: Date
}

struct PreviewStatus: Codable, Hashable {
    let status: String
    let preview_id: String?
}
