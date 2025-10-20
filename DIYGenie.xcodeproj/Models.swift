import Foundation

struct Plan: Codable {
    let planName: String
    let steps: [PlanStep]
}

struct PlanStep: Identifiable, Codable {
    let id = UUID()
    let stepName: String
    let description: String
}
