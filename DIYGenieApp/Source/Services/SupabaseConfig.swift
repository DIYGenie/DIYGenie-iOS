//
//  SupabaseConfig.swift
//  DIYGenieApp
//

import Foundation
import Supabase

/// Centralized configuration for all external services
struct SupabaseConfig {

    // MARK: - Supabase
    static let supabaseURL = URL(string: "https://qnevigmqyuxfzyczmctc.supabase.co")!
    static let anonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFuZXZpZ21xeXV4Znp5Y3ptY3RjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTg5NDc5MjUsImV4cCI6MjA3NDUyMzkyNX0.5wKtzwtNDZt6jjE5gYqNqqWATTdd7g2zVdHB231Z1wQ"

    // MARK: - External APIs
    static let decor8Key = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhcGlfa2V5X3V1aWQiOiJhMjI3MmU1Ni1iMmI4LTQzNTMtOTM3Ni1hNzQ2YjlkZTAyYTUiLCJpYXQiOjE3NjE4NjEzMjJ9.rVAr8Utdsd1Pqkecveyb-zcTltwe1XeeZGlZQE12-tU"
    static let openAIKey = "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"

    // MARK: - Stripe (optional)
    static let stripeSecretKey = "sk_test_51S7RTFPRupSX9rqpjWmcNHRShrvaoP3LjmBLOPFirTrcUNxDTfzSiE3Ksmmg97vl0ypMn2GNkWmddHjm7XOhL0QP00Pxpuq5Y2"

    // MARK: - Client
    static let client: SupabaseClient = {
        SupabaseClient(supabaseURL: supabaseURL, supabaseKey: anonKey)
    }()
}
