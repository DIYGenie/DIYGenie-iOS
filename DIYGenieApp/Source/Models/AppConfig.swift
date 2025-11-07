import Foundation

enum AppConfig {
    // Already present:
    static var apiBaseURL: URL {            // from Info.plist key: API_BASE_URL
        let raw = Bundle.main.object(forInfoDictionaryKey: "API_BASE_URL") as? String ?? ""
        guard let url = URL(string: raw) else { fatalError("Missing/invalid API_BASE_URL") }
        return url
    }

    static var supabaseURL: URL {           // from Info.plist key: SUPABASE_URL
        let raw = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_URL") as? String ?? ""
        guard let url = URL(string: raw) else { fatalError("Missing/invalid SUPABASE_URL") }
        return url
    }

    static var supabaseAnonKey: String {    // from Info.plist key: SUPABASE_ANON_KEY
        (Bundle.main.object(forInfoDictionaryKey: "SUPABASE_ANON_KEY") as? String) ?? ""
    }

    // ✅ used by ProjectsService+Supabase
    // Build a public CDN URL for a Storage object
    static func publicURL(bucket: String, path: String) -> String {
        let url = supabaseURL
            .appendingPathComponent("storage/v1/object/public")
            .appendingPathComponent(bucket)
            .appendingPathComponent(path)
        return url.absoluteString
    }

    static var supabaseHeaders: [String: String] {
        [
            "apikey": supabaseAnonKey,
            "Authorization": "Bearer \(supabaseAnonKey)",
            "Content-Type": "application/json"
        ]
    }
}

