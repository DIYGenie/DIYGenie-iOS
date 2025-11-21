import Foundation

protocol PlanErrorTrackable {
    func trackPlanError(code: String, missingFields: [String])
}

/// Lightweight shim so analytics calls remain optional.
final class AnalyticsManager {
    static var shared: PlanErrorTrackable?
}
