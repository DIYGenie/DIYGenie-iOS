//
//  Project.swift
//  DIYGenieApp
//

import Foundation

/// Supabase `projects` row model.
/// Matches snake_case columns and provides convenient computed properties
/// used by your SwiftUI views (e.g., `input_image_url`).
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

    // Timestamps (keep as String to avoid date-format surprises)
    var created_at: String?
    var updated_at: String?

    // MARK: - Coding keys (map snake_case from Supabase)
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

    // MARK: - View helpers / compatibility

    /// What older code calls `input_image_url` (first prefer photo, then preview).
    var input_image_url: String? { photo_url ?? preview_url }

    /// Parsed convenience URLs (optional)
    var photoURL: URL?   { URL(string: photo_url ?? "") }
    var previewURL: URL? { URL(string: preview_url ?? "") }
    var arScanURL: URL?  { URL(string: ar_scan_url ?? "") }
}

