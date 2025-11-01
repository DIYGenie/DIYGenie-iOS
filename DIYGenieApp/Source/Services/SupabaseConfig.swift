//
//  SupabaseConfig.swift
//  DIYGenieApp
//

import Foundation
import Supabase

enum SupabaseConfig {
    static let client: SupabaseClient = {
        guard
            let urlString = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_URL") as? String,
            let key = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_ANON_KEY") as? String,
            let url = URL(string: urlString),
            !urlString.isEmpty,
            !key.isEmpty
        else {
            let allKeys = Bundle.main.infoDictionary?.keys.joined(separator: ", ") ?? "(none)"
            fatalError("❌ Missing Supabase credentials in Info.plist — available keys: \(allKeys)")
        }

        print("🟢 Supabase connected: \(urlString)")
        return SupabaseClient(supabaseURL: url, supabaseKey: key)
    }()
}
