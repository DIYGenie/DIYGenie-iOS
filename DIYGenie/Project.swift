import Foundation
import SwiftUI

struct Project: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let goal: String?
    var status: String?

    // Convenience initializer with default status of "created"
    init(id: String, name: String, goal: String?, status: String? = "created") {
        self.id = id
        self.name = name
        self.goal = goal
        self.status = status
    }
}

// MARK: - DTO convenience initializer
extension Project {
    init(dto: CreateProjectDTO) {
        self.init(
            id: dto.id.uuidString,
            name: dto.name,
            goal: dto.goal,
            status: "created"
        )
    }
}
