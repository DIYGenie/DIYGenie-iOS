import Foundation

/// Central place for runtime configuration pulled from Info.plist.
/// Keys required in Info.plist:
///  - API_BASE_URL (e.g. https://api.diygenieapp.com)
///  - SUPABASE_URL (e.g. https://xxxx.supabase.co)
///  - SUPABASE_ANON_KEY (string)
enum AppConfig {

    // MARK: - API (DIY Genie backend)
    static var apiBaseURL: URL {
        guard
            let raw = Bundle.main.object(forInfoDictionaryKey: "API_BASE_URL") as? String,
            let url = URL(string: raw)
        else { fatalError("❌ Missing/invalid API_BASE_URL in Info.plist") }
        return url
    }

    // MARK: - Supabase
    static var supabaseURL: URL {
        guard
            let raw = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_URL") as? String,
            let url = URL(string: raw)
        else { fatalError("❌ Missing/invalid SUPABASE_URL in Info.plist") }
        return url
    }

    static var supabaseAnonKey: String {
        guard
            let key = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_ANON_KEY") as? String,
            !key.isEmpty
        else { fatalError("❌ Missing SUPABASE_ANON_KEY in Info.plist") }
        return key
    }

    /// Helper to build a public storage URL for a file in a bucket.
    static func publicURL(bucket: String, path: String) -> URL {
        supabaseURL
            .appendingPathComponent("storage/v1/object/public/\(bucket)/\(path)")
    }
}

