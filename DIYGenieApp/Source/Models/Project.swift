import Foundation

struct Project: Codable, Identifiable {
    let id: String
    let userId: String
    let name: String
    let goal: String?
    let budget: String?
    let skillLevel: String?
    let createdAt: String?
    let originalImageUrl: String?
    let originalImageURL: String?
    let previewImageUrl: String?
    let previewURL: String?
    let roomScanUrl: String?
    let roomPlanFileUrl: String?
    let planText: String?
    let costEstimate: String?
    let toolsAndMaterials: [String?]?   // ← optional inner type fixed
    let steps: [String?]?               // ← optional inner type fixed
    let beforeImageUrl: String?
    let afterImageUrl: String?
}

