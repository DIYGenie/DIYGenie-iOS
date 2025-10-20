// DIYGenie/Project+ID.swift
import Foundation

extension Project {
    /// Safely converts a String-based `id` to `UUID`.
    /// Falls back to a random UUID if the string is malformed.
    func idAsUUID() -> UUID {
        UUID(uuidString: id) ?? UUID()
    }
}
