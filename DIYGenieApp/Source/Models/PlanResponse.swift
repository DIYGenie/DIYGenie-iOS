import Foundation

struct PlanResponse: Codable {
    let title: String
    let steps: [String]
    let tools: [String]
    let materials: [String]
    let costEstimate: Double?
    let timeEstimate: String?
}
