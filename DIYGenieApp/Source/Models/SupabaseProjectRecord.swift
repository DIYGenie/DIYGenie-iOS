//
//  SupabaseProjectRecord.swift
//  DIYGenieApp
//

import Foundation

struct SupabaseProjectRecord: Codable {
    let id: String
    let userId: String?
    let name: String
    let goal: String?
    let budget: String?
    let budgetTier: String?
    let skillLevel: String?
    let status: String?
    let createdAt: String?
    let updatedAt: String?
    let previewUrl: String?
    let inputImageUrl: String?
    let arProvider: String?
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
    let previewJobId: String?

    let previewPasses: [SupabasePreviewPassRecord]?
    let profiles: SupabaseProfileRecord?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case name
        case goal
        case budget
        case budgetTier = "budget_tier"
        case skillLevel = "skill_level"
        case status
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case previewUrl = "preview_url"
        case inputImageUrl = "input_image_url"
        case arProvider = "ar_provider"
        case arConfidence = "ar_confidence"
        case scalePxPerIn = "scale_px_per_in"
        case calibrationMethod = "calibration_method"
        case referenceObject = "reference_object"
        case roomType = "room_type"
        case scanJson = "scan_json"
        case dimensionsJson = "dimensions_json"
        case floorplanSvg = "floorplan_svg"
        case deviceModel = "device_model"
        case osVersion = "os_version"
        case appVersion = "app_version"
        case scanAt = "scan_at"
        case isTest = "is_test"
        case planJson = "plan_json"
        case completedSteps = "completed_steps"
        case currentStepIndex = "current_step_index"
        case previewStatus = "preview_status"
        case previewMeta = "preview_meta"
        case isDemo = "is_demo"
        case previewJobId = "preview_job_id"
        case previewPasses = "preview_passes"
        case profiles
    }

    func toProject() -> Project {
        let mergedPreviewURL = previewUrl ?? previewPasses?.last?.previewUrl
        let mergedStatus = previewStatus ?? previewPasses?.last?.status
        let mergedPlan = planJson ?? previewPasses?.last?.planJson

        return Project(
            id: id,
            userId: userId ?? "",
            name: name,
            goal: goal,
            budget: budget,
            budgetTier: budgetTier,
            skillLevel: skillLevel,
            status: mergedStatus ?? status,
            createdAt: createdAt,
            updatedAt: updatedAt,
            preview_url: mergedPreviewURL,
            input_image_url: inputImageUrl,
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
            planJson: mergedPlan,
            completedSteps: completedSteps,
            currentStepIndex: currentStepIndex,
            previewStatus: mergedStatus,
            previewMeta: previewMeta,
            isDemo: isDemo
        )
    }
}
