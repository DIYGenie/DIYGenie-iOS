import Foundation

enum BudgetSelection: CaseIterable, Equatable {
    case one, two, three

    var symbol: String {
        switch self {
        case .one:   return "$"
        case .two:   return "$$"
        case .three: return "$$$"
        }
    }
}

enum SkillSelection: String, CaseIterable, Equatable {
    case beginner, intermediate, advanced

    var label: String {
        rawValue.capitalized
    }
}
