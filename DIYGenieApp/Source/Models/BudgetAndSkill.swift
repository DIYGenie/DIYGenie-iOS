import Foundation

// MARK: - Budget & Skill models (single source of truth)

enum BudgetSelection: String, CaseIterable, Identifiable, Equatable {
    case one = "$"
    case two = "$$"
    case three = "$$$"

    var id: String { rawValue }
    var symbol: String { rawValue }
}

enum SkillSelection: String, CaseIterable, Identifiable, Equatable {
    case beginner
    case intermediate
    case advanced

    var id: String { rawValue }
    var label: String { rawValue.capitalized }
}

