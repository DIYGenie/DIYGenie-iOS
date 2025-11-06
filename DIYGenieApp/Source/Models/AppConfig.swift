import Foundation

/// App / Supabase config loaded from Info.plist (with safe fallbacks for dev)
enum AppConfig {
    /// Your public API base (webhooks) – used for /api/projects/:id/preview
    static var apiBaseURL: URL = {
        // Try Info.plist first; fall back to your known base
        let raw = Bundle.main.object(forInfoDictionaryKey: "API_BASE_URL") as? String
        return URL(string: raw ?? "https://api.diygenieapp.com")!
    }()

    /// Supabase project URL (e.g. https://xxxxx.supabase.co)
    static var supabaseURL: URL = {
        let raw = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_URL") as? String
        // Dev fallback from your logs:
        return URL(string: raw ?? "https://qnevigmqyuxfzyczmctc.supabase.co")!
    }()

    /// Supabase anon key (public) – must be in Info.plist as SUPABASE_ANON_KEY
    static var supabaseAnonKey: String = {
        let key = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_ANON_KEY") as? String ?? ""
        if key.isEmpty {
            // This will still compile; at runtime it will crash if missing
            fatalError("Missing SUPABASE_ANON_KEY in Info.plist")
        }
        return key
    }()

    /// Convenience: standard headers for PostgREST / Storage
    static var supabaseHeaders: [String: String] {
        [
            "apikey": AppConfig.supabaseAnonKey,
            "Authorization": "Bearer \(AppConfig.supabaseAnonKey)",
            "Content-Type": "application/json"
        ]
    }
}

