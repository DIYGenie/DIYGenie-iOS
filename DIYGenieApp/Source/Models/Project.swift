import Foundation

struct Project: Identifiable, Codable {
    let id: UUID
    let name: String
    let goal: String
    let budget: String
    let skillLevel: String
    let imagePath: String?
    let measuredWidthInches: Double?
    let measuredHeightInches: Double?
    let previewURL: String?
    let wantsPreview: Bool
}
