
import Foundation

/// Centralized configuration for Supabase credentials.
/// NOTE: Consider moving secrets to a secure location (e.g., configuration files, Keychain, or build settings) for production.
enum SupabaseConfig {
    static let url: String = "https://qnevigmqyuxfzyczmctc.supabase.co"
    static let anonKey: String = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFuZXZpZ21xeXV4Znp5Y3ptY3RjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTg5NDc5MjUsImV4cCI6MjA3NDUyMzkyNX0.5wKtzwtNDZt6jjE5gYqNqqWATTdd7g2zVdHB231Z1wQ"
}
