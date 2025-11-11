//
//  BudgetAndSkill.swift
//  DIYGenieApp
//
//  Single source of truth for budget/skill enums used across the app.
//

import Foundation

public enum SkillSelection: String, CaseIterable, Identifiable, Codable {
    case beginner
    case intermediate
    case advanced

    public var id: String { rawValue }

    public var label: String {
        switch self {
        case .beginner:     return "Beginner"
        case .intermediate: return "Intermediate"
        case .advanced:     return "Advanced"
        }
    }
}

public enum BudgetSelection: Int, CaseIterable, Identifiable, Codable {
    case one = 0     // $
    case two = 1     // $$
    case three = 2   // $$$

    public var id: Int { rawValue }

    public var label: String {
        switch self {
        case .one:   return "$"
        case .two:   return "$$"
        case .three: return "$$$"
        }
    }
}
