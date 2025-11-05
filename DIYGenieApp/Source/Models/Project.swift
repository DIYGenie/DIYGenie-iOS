// Models/Project.swift
import Foundation

/// Supabase `projects` row model (app target)
struct Project: Codable, Identifiable, Hashable {
    // Core columns
    let id: String
    var name: String?
    var description: String?
    var userId: String?

    // URLs stored in the table
    var photo_url: String?
    var preview_url: String?
    var ar_scan_url: String?

    // Timestamps (keep as String unless you want Date decoding)
    var created_at: String?
    var updated_at: String?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case description
        case userId = "user_id"
        case photo_url
        case preview_url
        case ar_scan_url
        case created_at
        case updated_at
    }
}

