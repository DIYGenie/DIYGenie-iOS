//
//  DIYGenieApp.swift
//  DIYGenieApp
//

import SwiftUI

@main
struct DIYGenieApp: App {

    // ✅ Override only in DEBUG so TestFlight/App Store aren’t affected
    #if DEBUG
    private let debugTestUserId: String? = "99198c4b-8470-49e2-895c-75593c5aa181"
    #else
    private let debugTestUserId: String? = nil
    #endif

    init() {
        ensureUserId(using: debugTestUserId)
        sanityLogEnvironment()
    }

    var body: some Scene {
        WindowGroup {
            RootTabs()
                .tint(.purple)
        }
    }
}

// MARK: - Private helpers
private extension DIYGenieApp {
    /// Ensures we always have a valid, non-empty user_id in UserDefaults.
    /// If `override` is provided (Debug only), it will be set explicitly.
    func ensureUserId(using override: String?) {
        let key = "user_id"
        let defaults = UserDefaults.standard

        // Clear any accidental blank
        if let existing = defaults.string(forKey: key), existing.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            defaults.removeObject(forKey: key)
            print("⚠️ Blank user_id found → removed")
        }

        if let override = override, !override.isEmpty {
            // Force the debug user id so your seeded project shows up
            defaults.set(override, forKey: key)
            print("🧪 DEBUG user_id override set → \(override)")
            return
        }

        // Normal path: keep existing or create a new one
        if let existing = defaults.string(forKey: key), !existing.isEmpty {
            print("✅ Existing user_id → \(existing)")
        } else {
            let newId = UUID().uuidString
            defaults.set(newId, forKey: key)
            print("🟢 Generated new user_id → \(newId)")
        }
    }

    /// Quick visibility to catch missing plist values early during dev.
    func sanityLogEnvironment() {
        let info = Bundle.main.infoDictionary ?? [:]
        let supabaseURL = info["SUPABASE_URL"] as? String ?? "(missing)"
        let apiBase = info["API_BASE_URL"] as? String ?? "(missing)"

        #if DEBUG
        print("🔧 ENV → SUPABASE_URL=\(supabaseURL)")
        print("🔧 ENV → API_BASE_URL=\(apiBase)")
        #endif
    }
}

