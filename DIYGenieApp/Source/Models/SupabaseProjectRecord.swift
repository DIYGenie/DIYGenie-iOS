//
//  SupabaseProjectRecord.swift
//  DIYGenieApp
//

import Foundation

struct SupabaseProjectRecord: Decodable {
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
    let photoUrl: String?

    let previewPasses: [SupabasePreviewPassRecord]?
    let profiles: SupabaseProfileRecord?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case userIdCamel = "userId"
        case name
        case goal
        case budget
        case budgetTier = "budget_tier"
        case budgetTierCamel = "budgetTier"
        case skillLevel = "skill_level"
        case skillLevelCamel = "skillLevel"
        case status
        case createdAt = "created_at"
        case createdAtCamel = "createdAt"
        case updatedAt = "updated_at"
        case updatedAtCamel = "updatedAt"
        case previewUrl = "preview_url"
        case previewUrlCamel = "previewUrl"
        case inputImageUrl = "input_image_url"
        case inputImageUrlCamel = "inputImageUrl"
        case arProvider = "ar_provider"
        case arProviderCamel = "arProvider"
        case arConfidence = "ar_confidence"
        case arConfidenceCamel = "arConfidence"
        case scalePxPerIn = "scale_px_per_in"
        case scalePxPerInCamel = "scalePxPerIn"
        case calibrationMethod = "calibration_method"
        case calibrationMethodCamel = "calibrationMethod"
        case referenceObject = "reference_object"
        case referenceObjectCamel = "referenceObject"
        case roomType = "room_type"
        case roomTypeCamel = "roomType"
        case scanJson = "scan_json"
        case scanJsonCamel = "scanJson"
        case dimensionsJson = "dimensions_json"
        case dimensionsJsonCamel = "dimensionsJson"
        case floorplanSvg = "floorplan_svg"
        case floorplanSvgCamel = "floorplanSvg"
        case deviceModel = "device_model"
        case deviceModelCamel = "deviceModel"
        case osVersion = "os_version"
        case osVersionCamel = "osVersion"
        case appVersion = "app_version"
        case appVersionCamel = "appVersion"
        case scanAt = "scan_at"
        case scanAtCamel = "scanAt"
        case isTest = "is_test"
        case isTestCamel = "isTest"
        case planJsonSnake = "plan_json"
        case planJsonCamel = "planJson"
        case completedStepsSnake = "completed_steps"
        case completedStepsCamel = "completedSteps"
        case currentStepIndex = "current_step_index"
        case currentStepIndexCamel = "currentStepIndex"
        case previewStatus = "preview_status"
        case previewStatusCamel = "previewStatus"
        case previewMeta = "preview_meta"
        case previewMetaCamel = "previewMeta"
        case isDemo = "is_demo"
        case isDemoCamel = "isDemo"
        case previewJobId = "preview_job_id"
        case previewJobIdCamel = "previewJobId"
        case photoUrl = "photo_url"
        case photoUrlCamel = "photoUrl"
        case previewPasses
        case profiles
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(String.self, forKey: .id)
        userId = try container.decodeIfPresent(String.self, forKey: .userId)
            ?? container.decodeIfPresent(String.self, forKey: .userIdCamel)
        name = try container.decode(String.self, forKey: .name)
        goal = try container.decodeIfPresent(String.self, forKey: .goal)
        budget = try container.decodeIfPresent(String.self, forKey: .budget)
        budgetTier = try container.decodeIfPresent(String.self, forKey: .budgetTier)
            ?? container.decodeIfPresent(String.self, forKey: .budgetTierCamel)
        skillLevel = try container.decodeIfPresent(String.self, forKey: .skillLevel)
            ?? container.decodeIfPresent(String.self, forKey: .skillLevelCamel)
        status = try container.decodeIfPresent(String.self, forKey: .status)

        createdAt = try container.decodeIfPresent(String.self, forKey: .createdAt)
            ?? container.decodeIfPresent(String.self, forKey: .createdAtCamel)
        updatedAt = try container.decodeIfPresent(String.self, forKey: .updatedAt)
            ?? container.decodeIfPresent(String.self, forKey: .updatedAtCamel)

        previewUrl = try container.decodeIfPresent(String.self, forKey: .previewUrl)
            ?? container.decodeIfPresent(String.self, forKey: .previewUrlCamel)
        inputImageUrl = try container.decodeIfPresent(String.self, forKey: .inputImageUrl)
            ?? container.decodeIfPresent(String.self, forKey: .inputImageUrlCamel)

        arProvider = try container.decodeIfPresent(String.self, forKey: .arProvider)
            ?? container.decodeIfPresent(String.self, forKey: .arProviderCamel)
        arConfidence = try container.decodeIfPresent(Double.self, forKey: .arConfidence)
            ?? container.decodeIfPresent(Double.self, forKey: .arConfidenceCamel)
        scalePxPerIn = try container.decodeIfPresent(Double.self, forKey: .scalePxPerIn)
            ?? container.decodeIfPresent(Double.self, forKey: .scalePxPerInCamel)
        calibrationMethod = try container.decodeIfPresent(String.self, forKey: .calibrationMethod)
            ?? container.decodeIfPresent(String.self, forKey: .calibrationMethodCamel)
        referenceObject = try container.decodeIfPresent(String.self, forKey: .referenceObject)
            ?? container.decodeIfPresent(String.self, forKey: .referenceObjectCamel)
        roomType = try container.decodeIfPresent(String.self, forKey: .roomType)
            ?? container.decodeIfPresent(String.self, forKey: .roomTypeCamel)

        scanJson = try container.decodeIfPresent([String: AnyCodable].self, forKey: .scanJson)
            ?? container.decodeIfPresent([String: AnyCodable].self, forKey: .scanJsonCamel)
        dimensionsJson = try container.decodeIfPresent([String: AnyCodable].self, forKey: .dimensionsJson)
            ?? container.decodeIfPresent([String: AnyCodable].self, forKey: .dimensionsJsonCamel)
        floorplanSvg = try container.decodeIfPresent(String.self, forKey: .floorplanSvg)
            ?? container.decodeIfPresent(String.self, forKey: .floorplanSvgCamel)

        deviceModel = try container.decodeIfPresent(String.self, forKey: .deviceModel)
            ?? container.decodeIfPresent(String.self, forKey: .deviceModelCamel)
        osVersion = try container.decodeIfPresent(String.self, forKey: .osVersion)
            ?? container.decodeIfPresent(String.self, forKey: .osVersionCamel)
        appVersion = try container.decodeIfPresent(String.self, forKey: .appVersion)
            ?? container.decodeIfPresent(String.self, forKey: .appVersionCamel)
        scanAt = try container.decodeIfPresent(String.self, forKey: .scanAt)
            ?? container.decodeIfPresent(String.self, forKey: .scanAtCamel)

        isTest = try container.decodeIfPresent(Bool.self, forKey: .isTest)
            ?? container.decodeIfPresent(Bool.self, forKey: .isTestCamel)
        planJson = try container.decodeIfPresent(PlanResponse.self, forKey: .planJsonCamel)
            ?? container.decodeIfPresent(PlanResponse.self, forKey: .planJsonSnake)
        completedSteps = try container.decodeIfPresent([Int].self, forKey: .completedStepsCamel)
            ?? container.decodeIfPresent([Int].self, forKey: .completedStepsSnake)
        currentStepIndex = try container.decodeIfPresent(Int.self, forKey: .currentStepIndex)
            ?? container.decodeIfPresent(Int.self, forKey: .currentStepIndexCamel)
        previewStatus = try container.decodeIfPresent(String.self, forKey: .previewStatus)
            ?? container.decodeIfPresent(String.self, forKey: .previewStatusCamel)
        previewMeta = try container.decodeIfPresent([String: AnyCodable].self, forKey: .previewMeta)
            ?? container.decodeIfPresent([String: AnyCodable].self, forKey: .previewMetaCamel)
        isDemo = try container.decodeIfPresent(Bool.self, forKey: .isDemo)
            ?? container.decodeIfPresent(Bool.self, forKey: .isDemoCamel)
        previewJobId = try container.decodeIfPresent(String.self, forKey: .previewJobId)
            ?? container.decodeIfPresent(String.self, forKey: .previewJobIdCamel)
        photoUrl = try container.decodeIfPresent(String.self, forKey: .photoUrl)
            ?? container.decodeIfPresent(String.self, forKey: .photoUrlCamel)

        previewPasses = try container.decodeIfPresent([SupabasePreviewPassRecord].self, forKey: .previewPasses)
        profiles = try container.decodeIfPresent(SupabaseProfileRecord.self, forKey: .profiles)
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
            previewUrl: mergedPreviewURL,
            inputImageUrl: inputImageUrl,
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
            isDemo: isDemo,
            photoUrl: photoUrl
        )
    }
}
