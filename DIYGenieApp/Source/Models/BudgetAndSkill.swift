import Foundation

// MARK: - Budget & Skill models (single source of truth)

enum BudgetSelection: String, CaseIterable, Identifiable, Equatable, Hashable {
    case one = "$", two = "$$", three = "$$$"
    var id: String { rawValue }
    var label: String { rawValue }
}

enum SkillSelection: String, CaseIterable {
    case beginner, intermediate, advanced
    var label: String {
        switch self {
        case .beginner: return "Beginner"
        case .intermediate: return "Intermediate"
        case .advanced: return "Advanced"
        }
    }
    var dbValue: String { rawValue }  // "beginner", "intermediate", "advanced"
}
