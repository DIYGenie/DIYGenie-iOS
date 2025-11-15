//
//  UserSession.swift
//  DIYGenieApp
//
//  Central place to read/write the persistent user identifier so
//  every view uses the same value and we never accidentally
//  generate a fresh UUID mid-session.
//

import Foundation

enum UserSession {
    private static let key = "user_id"

    static func currentUserID() -> String {
        let defaults = UserDefaults.standard
        if let existing = defaults.string(forKey: key), !existing.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return existing
        }

        let newValue = UUID().uuidString
        defaults.set(newValue, forKey: key)
        return newValue
    }
}

