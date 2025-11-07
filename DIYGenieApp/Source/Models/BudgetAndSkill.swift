import Foundation

// MARK: - Budget & Skill models (single source of truth)

enum BudgetSelection: String, CaseIterable, Identifiable, Equatable, Hashable {
    case one = "$", two = "$$", three = "$$$"
    var id: String { rawValue }
    var label: String { rawValue }
}

enum SkillSelection: String, CaseIterable, Identifiable, Equatable, Hashable {
    case beginner, intermediate, advanced
    var id: String { rawValue }
    var label: String { rawValue.capitalized }
}
