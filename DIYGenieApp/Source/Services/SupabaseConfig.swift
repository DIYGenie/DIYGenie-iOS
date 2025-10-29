//
//  SupabaseConfig.swift
//  DIYGenieApp
//

import Foundation

enum SupabaseConfig {
    // These two come from your Supabase dashboard or Secrets
    static let url = "https://qnevigmqyuxfzyczmctc.supabase.co"
    static let key = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFuZXZpZ21xeXV4Znp5Y3ptY3RjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTg5NDc5MjUsImV4cCI6MjA3NDUyMzkyNX0.5wKtzwtNDZt6jjE5gYqNqqWATTdd7g2zVdHB231Z1wQ"

    // This is your backend webhook base (Replit or API Gateway)
    static let baseURL = "https://api.diygenieapp.com"
}
