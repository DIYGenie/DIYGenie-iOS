import Foundation

struct Event: Codable, Identifiable, Hashable {
    let id: UUID
    let name: String
    let metadata: [String: String]?
    let createdAt: Date?

    init(id: UUID = UUID(), name: String, metadata: [String: String]? = nil, createdAt: Date? = nil) {
        self.id = id
        self.name = name
        self.metadata = metadata
        self.createdAt = createdAt
    }
}
