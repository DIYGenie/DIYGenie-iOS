//
//  SupabaseConfig.swift
//  DIYGenieApp
//
//  FINAL – Production-safe configuration for Xcode 26
//

import Foundation
import Supabase

struct SupabaseConfig {
    // 🔹 Supabase credentials (safe to include anon key + URL)
    static let supabaseURL = URL(string: "https://qnevigmqyuxfzyczmctc.supabase.co")!
    static let supabaseAnonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFuZXZpZ21xeXV4Znp5Y3ptY3RjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTg5NDc5MjUsImV4cCI6MjA3NDUyMzkyNX0.5wKtzwtNDZt6jjE5gYqNqqWATTdd7g2zVdHB231Z1wQ"

    // Supabase client
    static let client = SupabaseClient(
        supabaseURL: supabaseURL,
        supabaseKey: supabaseAnonKey
    )

    // 🔒 Sensitive API keys (loaded from environment variables)
    static let openAIKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"] ?? ""
    static let stripeSecret = ProcessInfo.processInfo.environment["STRIPE_SECRET_KEY"] ?? ""

    // Optional future variables (safe placeholders)
    static let decor8Key = ProcessInfo.processInfo.environment["DECOR8_API_KEY"] ?? ""
}

