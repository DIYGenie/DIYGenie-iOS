import Foundation

struct Project: Codable, Identifiable, Hashable {
    let id: String
    let title: String
    let description: String?
    let previews: [Preview]?
    let createdAt: Date?
    let updatedAt: Date?
}
