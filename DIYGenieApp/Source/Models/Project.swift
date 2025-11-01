//
//  Project.swift
//  DIYGenieApp
//
//  Mirrors Supabase table: public.projects
//  Updated: 2025-11-01
//

import Foundation

struct Project: Identifiable, Codable {
    // Core identifiers
    let id: String
    let user_id: String

    // Basic details
    let name: String
    let goal: String?
    let budget_tier: String?
    let skill_level: String?
    let status: String
    let budget: String?

    // Media / preview
    let input_image_url: String?
    let preview_url: String?
    let preview_status: String?
    let preview_meta: [String: String]?

    // AR / scanning data
    let ar_provider: String?
    let ar_confidence: Double?
    let scale_px_per_in: Double?
    let calibration_method: String?
    let reference_object: String?
    let room_type: String?
    let scan_json: [String: AnyCodable]?
    let dimensions_json: [String: AnyCodable]?
    let floorplan_svg: String?
    let device_model: String?
    let os_version: String?
    let app_version: String?
    let scan_at: String?

    // Plan + progress
    let plan_json: PlanResponse?
    let completed_steps: [Int]?
    let current_step_index: Int?

    // Flags
    let is_test: Bool?
    let is_demo: Bool?

    // Metadata
    let created_at: String
    let updated_at: String
}

// MARK: - Helpers
extension Project {
    var imageURL: URL? {
        if let preview = preview_url, !preview.isEmpty {
            return URL(string: preview)
        } else if let input = input_image_url, !input.isEmpty {
            return URL(string: input)
        }
        return nil
    }

    var hasPreview: Bool {
        preview_url != nil && !(preview_url ?? "").isEmpty
    }
}

// MARK: - AnyCodable (lightweight, Codable only)
struct AnyCodable: Codable {
    let value: Any

    init(_ value: Any) { self.value = value }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let intVal = try? container.decode(Int.self) {
            value = intVal
        } else if let doubleVal = try? container.decode(Double.self) {
            value = doubleVal
        } else if let boolVal = try? container.decode(Bool.self) {
            value = boolVal
        } else if let stringVal = try? container.decode(String.self) {
            value = stringVal
        } else if let dictVal = try? container.decode([String: AnyCodable].self) {
            value = dictVal
        } else if let arrayVal = try? container.decode([AnyCodable].self) {
            value = arrayVal
        } else {
            value = ()
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch value {
        case let intVal as Int:
            try container.encode(intVal)
        case let doubleVal as Double:
            try container.encode(doubleVal)
        case let boolVal as Bool:
            try container.encode(boolVal)
        case let stringVal as String:
            try container.encode(stringVal)
        case let dictVal as [String: AnyCodable]:
            try container.encode(dictVal)
        case let arrayVal as [AnyCodable]:
            try container.encode(arrayVal)
        default:
            try container.encodeNil()
        }
    }
}

