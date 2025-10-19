import Foundation

/// Represents different budget tiers for projects, indicating the relative budget level.
/// Used to categorize projects by their budget size.
public enum BudgetTier: String, Codable, CaseIterable, Sendable {
    /// Budget tier one, representing the lowest budget level.
    case one
    /// Budget tier two.
    case two
    /// Budget tier three.
    case three
    /// Budget tier four.
    case four
    /// Budget tier five, representing the highest budget level.
    case five
}

/// Represents different skill levels required or possessed.
/// Used to specify the expertise level for tasks or roles.
public enum SkillLevel: String, Codable, CaseIterable, Sendable {
    /// Beginner skill level, suitable for newcomers or those with basic knowledge.
    case beginner
    /// Intermediate skill level, suitable for those with some experience.
    case intermediate
    /// Advanced skill level, suitable for those with significant expertise.
    case advanced
    /// Expert skill level, suitable for those with deep mastery or specialization.
    case expert
}
