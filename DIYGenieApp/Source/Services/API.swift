//
//  API.swift
//  DIYGenieApp
//
//  Your backend base URL (NOT the Supabase URL).
//

import Foundation

enum API {
    static let baseURL: String = {
        guard let s = Bundle.main.object(forInfoDictionaryKey: "API_BASE_URL") as? String, !s.isEmpty else {
            fatalError("Missing API_BASE_URL in Info.plist")
        }
        // No trailing slash
        return s.hasSuffix("/") ? String(s.dropLast()) : s
    }()
}

