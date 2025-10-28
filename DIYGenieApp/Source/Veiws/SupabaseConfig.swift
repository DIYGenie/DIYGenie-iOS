// SupabaseConfig.swift
import Foundation

struct SupabaseConfig {
    static let url = URL(string: Bundle.main.object(forInfoDictionaryKey: "https://qnevigmqyuxfzyczmctc.supabase.co") as? String ?? "")!
    static let anonKey = Bundle.main.object(forInfoDictionaryKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFuZXZpZ21xeXV4Znp5Y3ptY3RjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTg5NDc5MjUsImV4cCI6MjA3NDUyMzkyNX0.5wKtzwtNDZt6jjE5gYqNqqWATTdd7g2zVdHB231Z1wQ") as? String ?? ""
}

