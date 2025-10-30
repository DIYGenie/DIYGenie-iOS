//
//  SupabaseConfig.swift
//  DIYGenieApp
//

import Foundation
import Supabase

enum SupabaseConfig {
    // MARK: - Constants
    static let baseURL = URL(string: "https://qnevigmqyuxfzyczmctc.supabase.co")!
    static let anonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFuZXZpZ21xeXV4Znp5Y3ptY3RjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTg5NDc5MjUsImV4cCI6MjA3NDUyMzkyNX0.5wKtzwtNDZt6jjE5gYqNqqWATTdd7g2zVdHB231Z1wQ"

    // MARK: - Client
    static let client = SupabaseClient(
        supabaseURL: baseURL,
        supabaseKey: anonKey
    )

    // MARK: - Decor8
    static let decor8Key = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhcGlfa2V5X3V1aWQiOiJhMjI3MmU1Ni1iMmI4LTQzNTMtOTM3Ni1hNzQ2YjlkZTAyYTUiLCJpYXQiOjE3NjE4NjEzMjJ9.rVAr8Utdsd1Pqkecveyb-zcTltwe1XeeZGlZQE12-tU"
}
