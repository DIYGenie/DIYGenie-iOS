//
//  SupabaseConfig.swift
//  DIYGenieApp
//

import Foundation
import Supabase

enum SupabaseConfig {
    // MARK: - Static Supabase Client
    static let client: SupabaseClient = {
        guard
            let supabaseUrlString = Bundle.main.object(forInfoDictionaryKey: "https://qnevigmqyuxfzyczmctc.supabase.co") as? String,
            let supabaseKey = Bundle.main.object(forInfoDictionaryKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFuZXZpZ21xeXV4Znp5Y3ptY3RjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTg5NDc5MjUsImV4cCI6MjA3NDUyMzkyNX0.5wKtzwtNDZt6jjE5gYqNqqWATTdd7g2zVdHB231Z1wQ") as? String,
            let supabaseUrl = URL(string: supabaseUrlString)
        else {
            fatalError("❌ Missing Supabase credentials in Info.plist")
        }

        // ✅ Create the global Supabase client
        return SupabaseClient(
            supabaseURL: supabaseUrl,
            supabaseKey: supabaseKey
        )
    }()
}
