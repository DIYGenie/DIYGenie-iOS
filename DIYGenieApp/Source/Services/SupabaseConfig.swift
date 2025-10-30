//
//  SupabaseConfig.swift
//  DIYGenieApp
//
//  Created by Tye Kowalski on 10/30/25.
//

import Foundation
import Supabase

// MARK: - Supabase Environment Configuration
enum SupabaseConfig {
    
    // ✅ Replace these with your real Supabase project credentials
    static let supabaseURL = URL(string: "https://qnevigmqyuxfzyczmctc.supabase.co")!
    static let supabaseAnonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFuZXZpZ21xeXV4Znp5Y3ptY3RjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTg5NDc5MjUsImV4cCI6MjA3NDUyMzkyNX0.5wKtzwtNDZt6jjE5gYqNqqWATTdd7g2zVdHB231Z1wQ"
    
    // MARK: - Shared Supabase Client
    static let client = SupabaseClient(
        supabaseURL: supabaseURL,
        supabaseKey: supabaseAnonKey
    )
}
