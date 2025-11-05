//  Project.swift
//  DIYGenieApp
//
//  Single authoritative model for Supabase `public.projects`.
//  Matches your schema and keeps snake_case via CodingKeys.
//  Keep this as the ONLY `Project` type in the app target.

import Foundation

// If you placed AnyCodable in a different module/file, keep that import path consistent.
struct Project: Codable, Identifiable, Hashable {

    // MARK: - Core
    let id: String                   // uuid
    var userId: String               // user_id
    var name: String
    var status: String               // default 'draft'

    // MARK: - Optional descriptors
    var goal: String?
    var budgetTier: String?          // '$' '$$' '$$$'
    var skillLevel: String?          // 'beginner'|'intermediate'|'advanced'
    var budget: String?              // '$' '$$' '$$$' (default '$$')

    // MARK: - Media / AR
    var previewUrl: String?
    var inputImageUrl: String?
    var arProvider: String?
    var arConfidence: Double?
    var scalePxPerIn: Double?
    var calibrationMethod: String?
    var referenceObject: String?
    var roomType: String?

    // JSONB fields
    var scanJson: [String: AnyCodable]?
    var dimensionsJson: [String: AnyCodable]?
    var planJson: [String: AnyCodable]?
    var previewMeta: [String: AnyCodable]?

    // Other artifacts
    var floorplanSvg: String?
    var deviceModel: String?
    var osVersion: String?
    var appVersion: String?

    // Timing
    var createdAt: String            // keep as String to avoid date-format surprises
    var updatedAt: String
    var scanAt: String?

    // Flags / progress
    var isTest: Bool?
    var isDemo: Bool?
    var completedSteps: [Int]?
    var currentStepIndex: Int?
    var previewStatus: String?

    // MARK: - Coding keys (snake_case ↔ camelCase)
    enum CodingKeys: String, CodingKey {
        case id
        case userId            = "user_id"
        case name
        case status

        case goal
        case budgetTier        = "budget_tier"
        case skillLevel        = "skill_level"
        case budget

        case previewUrl        = "preview_url"
        case inputImageUrl     = "input_image_url"
        case arProvider        = "ar_provider"
        case arConfidence      = "ar_confidence"
        case scalePxPerIn      = "scale_px_per_in"
        case calibrationMethod = "calibration_method"
        case referenceObject   = "reference_object"
        case roomType          = "room_type"

        case scanJson          = "scan_json"
        case dimensionsJson    = "dimensions_json"
        case planJson          = "plan_json"
        case previewMeta       = "preview_meta"

        case floorplanSvg      = "floorplan_svg"
        case deviceModel       = "device_model"
        case osVersion         = "os_version"
        case appVersion        = "app_version"

        case createdAt         = "created_at"
        case updatedAt         = "updated_at"
        case scanAt            = "scan_at"

        case isTest            = "is_test"
        case isDemo            = "is_demo"
        case completedSteps    = "completed_steps"
        case currentStepIndex  = "current_step_index"
        case previewStatus     = "preview_status"
    }
}

