import Foundation

/// Represents a summary of a scanned room, including the area, number of walls,
/// and number of openings.  Provides formatted strings for display in the UI.
struct RoomSummary {
    /// The total floor area of the scanned room in square feet.
    var area: Double?
    /// The number of walls detected in the scan.
    var wallCount: Int?
    /// The number of openings detected (doors/windows) in the scan.
    var openingsCount: Int?

    /// A formatted string for the area (e.g. "120.00 sq ft"), or "N/A" if unknown.
    var formattedArea: String {
        if let area = area {
            return String(format: "%.2f sq ft", area)
        } else {
            return "N/A"
        }
    }

    /// A formatted string for the number of walls, or "N/A" if unknown.
    var formattedWalls: String {
        if let walls = wallCount {
            return "\(walls)"
        } else {
            return "N/A"
        }
    }

    /// A formatted string for the number of openings, or "N/A" if unknown.
    var formattedOpenings: String {
        if let openings = openingsCount {
            return "\(openings)"
        } else {
            return "N/A"
        }
    }
}