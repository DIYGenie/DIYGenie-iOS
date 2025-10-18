import Foundation

struct Preview: Codable, Identifiable, Hashable {
    let id: String
    let imageUrl: URL?
    let caption: String?
}
