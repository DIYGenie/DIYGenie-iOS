import Foundation

struct ProjectPreview: Codable, Identifiable, Hashable {
    let id: String
    let imageUrl: URL?
    let caption: String?
}
