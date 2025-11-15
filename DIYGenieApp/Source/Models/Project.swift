//
//  Project.swift
//  DIYGenieApp
//

import Foundation

public struct Project: Codable, Identifiable, Hashable {
    public let id: String
    public let userId: String
    public let name: String
    public let goal: String?
    public let budget: String?            // '$' | '$$' | '$$$'
    public let budgetTier: String?        // optional legacy
    public let skillLevel: String?        // 'beginner' | 'intermediate' | 'advanced'
    public let status: String?            // 'draft' | 'active' | etc.

    public let createdAt: String?
    public let updatedAt: String?

    public let preview_url: String?
    public let input_image_url: String?

    public let arProvider: String?        // 'roomplan' when AR scan saved
    public let arConfidence: Double?
    public let scalePxPerIn: Double?
    public let calibrationMethod: String?
    public let referenceObject: String?
    public let roomType: String?

    public let scanJson: [String: AnyCodable]?
    public let dimensionsJson: [String: AnyCodable]?
    public let floorplanSvg: String?

    public let deviceModel: String?
    public let osVersion: String?
    public let appVersion: String?
    public let scanAt: String?

    public let isTest: Bool?
    public let planJson: PlanResponse?
    public let completedSteps: [Int]?
    public let currentStepIndex: Int?
    public let previewStatus: String?
    public let previewMeta: [String: AnyCodable]?
    public let isDemo: Bool?

    // Convenience accessors used by UI
    public var previewURL: String? { preview_url }
    public var inputImageURL: String? { input_image_url }

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
