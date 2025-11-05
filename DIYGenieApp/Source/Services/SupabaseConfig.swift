//
//  SupabaseConfig.swift
//  DIYGenieApp
//
//  Production config + helpers (no models here).
//

import Foundation
import Supabase

enum SupabaseConfig {
    // MARK: - Read from Info.plist
    private static let supabaseURLString: String = {
        guard let s = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_URL") as? String,
              !s.isEmpty else {
            fatalError("Missing SUPABASE_URL in Info.plist")
        }
        return s
    }()

    private static let supabaseAnonKey: String = {
        guard let s = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_ANON_KEY") as? String,
              !s.isEmpty else {
            fatalError("Missing SUPABASE_ANON_KEY in Info.plist")
        }
        return s
    }()

    // MARK: - Project root, e.g. https://xxxxx.supabase.co
    static let baseURL: URL = {
        guard let url = URL(string: supabaseURLString) else {
            fatalError("Invalid SUPABASE_URL")
        }
        return url
    }()

    // MARK: - Shared Supabase client
    static let client: SupabaseClient = {
        SupabaseClient(supabaseURL: baseURL, supabaseKey: supabaseAnonKey)
    }()

    // MARK: - Public Storage URL builder (replacement for removed getPublicUrl)
    /// -> https://<project>.supabase.co/storage/v1/object/public/<bucket>/<path>
    static func publicURL(bucket: String, path: String) -> URL {
        baseURL
            .appendingPathComponent("storage/v1/object/public/\(bucket)/\(path)")
    }
}
