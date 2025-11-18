//
//  Project.swift
//  DIYGenieApp
//

import Foundation

struct Project: Codable, Identifiable {
    let id: String
    let userId: String
    let name: String
    let goal: String?
    let budget: String?            // '$' | '$$' | '$$$'
    let budgetTier: String?        // optional legacy
    let skillLevel: String?        // 'beginner' | 'intermediate' | 'advanced'
    let status: String?            // 'draft' | 'active' | etc.

    let createdAt: String?
    let updatedAt: String?

    let preview_url: String?
    let input_image_url: String?

    let arProvider: String?        // 'roomplan' when AR scan saved
    let arConfidence: Double?
    let scalePxPerIn: Double?
    let calibrationMethod: String?
    let referenceObject: String?
    let roomType: String?

    let scanJson: [String: AnyCodable]?
    let dimensionsJson: [String: AnyCodable]?
    let floorplanSvg: String?

    let deviceModel: String?
    let osVersion: String?
    let appVersion: String?
    let scanAt: String?

    let isTest: Bool?
    let planJson: PlanResponse?
    let completedSteps: [Int]?
    let currentStepIndex: Int?
    let previewStatus: String?
    let previewMeta: [String: AnyCodable]?
    let isDemo: Bool?

    // Convenience accessors used by UI
    var previewURL: String? { preview_url }
    var inputImageURL: String? { input_image_url }

    enum CodingKeys: String, CodingKey {
        case id
        case userId              = "user_id"
        case name
        case goal
        case budget
        case budgetTier          = "budget_tier"
        case skillLevel          = "skill_level"
        case status

        case createdAt           = "created_at"
        case updatedAt           = "updated_at"

        case preview_url
        case input_image_url

        case arProvider          = "ar_provider"
        case arConfidence        = "ar_confidence"
        case scalePxPerIn        = "scale_px_per_in"
        case calibrationMethod   = "calibration_method"
        case referenceObject     = "reference_object"
        case roomType            = "room_type"

        case scanJson            = "scan_json"
        case dimensionsJson      = "dimensions_json"
        case floorplanSvg        = "floorplan_svg"

        case deviceModel         = "device_model"
        case osVersion           = "os_version"
        case appVersion          = "app_version"
        case scanAt              = "scan_at"

        case isTest              = "is_test"
        case planJson            = "plan_json"
        case completedSteps      = "completed_steps"
        case currentStepIndex    = "current_step_index"
        case previewStatus       = "preview_status"
        case previewMeta         = "preview_meta"
        case isDemo              = "is_demo"
    }
}

extension Project {
    func replacing(updatedAt: String? = nil,
                   previewURL: String? = nil,
                   inputImageURL: String? = nil,
                   planJson: PlanResponse? = nil,
                   completedSteps: [Int]? = nil,
                   currentStepIndex: Int? = nil,
                   previewStatus: String? = nil,
                   previewMeta: [String: AnyCodable]? = nil) -> Project {
        Project(
            id: id,
            userId: userId,
            name: name,
            goal: goal,
            budget: budget,
            budgetTier: budgetTier,
            skillLevel: skillLevel,
            status: status,
            createdAt: createdAt,
            updatedAt: updatedAt ?? self.updatedAt,
            preview_url: previewURL ?? self.preview_url,
            input_image_url: inputImageURL ?? self.input_image_url,
            arProvider: arProvider,
            arConfidence: arConfidence,
            scalePxPerIn: scalePxPerIn,
            calibrationMethod: calibrationMethod,
            referenceObject: referenceObject,
            roomType: roomType,
            scanJson: scanJson,
            dimensionsJson: dimensionsJson,
            floorplanSvg: floorplanSvg,
            deviceModel: deviceModel,
            osVersion: osVersion,
            appVersion: appVersion,
            scanAt: scanAt,
            isTest: isTest,
            planJson: planJson ?? self.planJson,
            completedSteps: completedSteps ?? self.completedSteps,
            currentStepIndex: currentStepIndex ?? self.currentStepIndex,
            previewStatus: previewStatus ?? self.previewStatus,
            previewMeta: previewMeta ?? self.previewMeta,
            isDemo: isDemo
        )
    }
}

extension Project: Equatable {
    static func == (lhs: Project, rhs: Project) -> Bool {
        return lhs.id == rhs.id
    }
}

extension Project: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
