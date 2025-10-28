//
//  SupabaseConfig.swift
//  DIYGenieApp
//
//  Created by Tye on 10/28/25.
//

import Foundation
import Supabase

/// Reads Supabase credentials safely from environment variables or Info.plist.
struct SupabaseConfig {
    static var url: URL {
        if let envURL = ProcessInfo.processInfo.environment["SUPABASE_URL"],
           let url = URL(string: envURL) {
            return url
        }

        if let plistURL = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_URL") as? String,
           let url = URL(string: plistURL) {
            return url
        }

        fatalError("❌ Missing Supabase URL in environment or Info.plist")
    }

    static var key: String {
        if let envKey = ProcessInfo.processInfo.environment["SUPABASE_ANON_KEY"] {
            return envKey
        }

        if let plistKey = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_ANON_KEY") as? String {
            return plistKey
        }

        fatalError("❌ Missing Supabase anon key in environment or Info.plist")
    }
}

/// Global Supabase client
let client = SupabaseClient(
    supabaseURL: SupabaseConfig.url,
    supabaseKey: SupabaseConfig.key
)
