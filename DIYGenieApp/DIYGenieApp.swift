//
//  DIYGenieApp.swift
//

import SwiftUI

@main
struct DIYGenieApp: App {
    init() {
        // 🧩 Ensure a valid persistent user_id before anything else runs
        if let existing = UserDefaults.standard.string(forKey: "user_id"), existing.isEmpty {
            print("⚠️ Found blank user_id, resetting…")
            UserDefaults.standard.removeObject(forKey: "user_id")
        }

        if UserDefaults.standard.string(forKey: "user_id") == nil {
            let newId = UUID().uuidString
            UserDefaults.standard.set(newId, forKey: "user_id")
            print("🟢 Generated new user_id:", newId)
        } else {
            print("✅ Existing user_id:", UserDefaults.standard.string(forKey: "user_id") ?? "none")
        }
    }

    var body: some Scene {
        WindowGroup {
            RootTabs()
                .tint(.purple)
        }
    }
}

