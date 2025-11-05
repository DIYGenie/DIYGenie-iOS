//
//  Project.swift
//  DIYGenieApp
//

import Foundation

/// Mirrors the `public.projects` table in Supabase.
/// Field names are kept in snake_case to match your schema and existing views.
struct Project: Codable, Identifiable, Hashable {
    // Core
    let id: String
    let user_id: String
    let name: String
    let goal: String?
    let budget_tier: String?
    let skill_level: String?
    let status: String

    // Timestamps (as ISO-8601 strings to avoid tz decoding surprises)
    let created_at: String
    let updated_at: String

    // URLs saved in DB (used by UI)
    let preview_url: String?
    let input_image_url: String?

    // AR / measurement metadata
    let ar_provider: String?
    let ar_confidence: Double?
    let scale_px_per_in: Double?
    let calibration_method: String?
    let reference_object: String?
    let room_type: String?
    let scan_json: [String: AnyCodable]?
    let dimensions_json: [String: AnyCodable]?
    let floorplan_svg: String?
    let scan_at: String?

    // Device/app metadata
    let device_model: String?
    let os_version: String?
    let app_version: String?

    // Business flags & plan
    let is_test: Bool?
    let budget: String
    let plan_json: [String: AnyCodable]?
    let completed_steps: [Int]?
    let current_step_index: Int?
    let preview_status: String?
    let preview_meta: [String: AnyCodable]?
    let is_demo: Bool

    enum CodingKeys: String, CodingKey {
        case id
        case user_id
        case name
        case goal
        case budget_tier
        case skill_level
        case status
        case created_at
        case updated_at
        case preview_url
        case input_image_url

        case ar_provider
        case ar_confidence
        case scale_px_per_in
        case calibration_method
        case reference_object
        case room_type
        case scan_json
        case dimensions_json
        case floorplan_svg
        case scan_at

        case device_model
        case os_version
        case app_version

        case is_test
        case budget
        case plan_json
        case completed_steps
        case current_step_index
        case preview_status
        case preview_meta
        case is_demo
    }
}
