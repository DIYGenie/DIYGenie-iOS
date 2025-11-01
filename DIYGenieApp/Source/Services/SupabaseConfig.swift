//
//  SupabaseConfig.swift
//  DIYGenieApp
//

import Foundation
import Supabase

enum SupabaseConfig {
    // Read from Info.plist
    private static let supabaseURLString: String = {
        guard let s = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_URL") as? String, !s.isEmpty else {
            fatalError("Missing SUPABASE_URL in Info.plist")
        }
        return s
    }()

    private static let supabaseAnonKey: String = {
        guard let s = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_ANON_KEY") as? String, !s.isEmpty else {
            fatalError("Missing SUPABASE_ANON_KEY in Info.plist")
        }
        return s
    }()

    /// Supabase project root, e.g. https://xxxx.supabase.co
    static let baseURL: URL = {
        guard let url = URL(string: supabaseURLString) else {
            fatalError("Invalid SUPABASE_URL")
        }
        return url
    }()

    /// Shared Supabase client
    static let client: SupabaseClient = {
        SupabaseClient(supabaseURL: baseURL, supabaseKey: supabaseAnonKey)
    }()

    /// Build a public storage URL (replacement for removed getPublicUrl())
    /// -> https://<project>.supabase.co/storage/v1/object/public/<bucket>/<path>
    static func publicURL(bucket: String, path: String) -> URL {
        baseURL
            .appendingPathComponent("storage/v1/object/public/\(bucket)/\(path)")
    }
}

