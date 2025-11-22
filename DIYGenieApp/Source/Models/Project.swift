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

    let previewUrl: String?
    let inputImageUrl: String?

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
    let photoUrl: String?

    let metadata: ProjectMetadata?

    // Convenience accessors used by UI
    var previewURL: URL? {
        if let previewUrl, let url = URL(string: previewUrl) { return url }
        return nil
    }

    var inputImageURL: URL? {
        if let inputImageUrl, let url = URL(string: inputImageUrl) { return url }
        return nil
    }

    var planJSON: PlanResponse? { planJson }
    var estimatedCost: Double? { metadata?.estimatedCost }
    var estimatedDuration: String? { metadata?.estimatedDuration }
    var materials: [String]? { metadata?.materials }
    var skillLevelEstimate: String? { metadata?.skillLevel ?? skillLevel }

    init(id: String,
         userId: String,
         name: String,
         goal: String?,
         budget: String?,
         budgetTier: String?,
         skillLevel: String?,
         status: String?,
         createdAt: String?,
         updatedAt: String?,
         previewUrl: String?,
         inputImageUrl: String?,
         arProvider: String?,
         arConfidence: Double?,
         scalePxPerIn: Double?,
         calibrationMethod: String?,
         referenceObject: String?,
         roomType: String?,
         scanJson: [String: AnyCodable]?,
         dimensionsJson: [String: AnyCodable]?,
         floorplanSvg: String?,
         deviceModel: String?,
         osVersion: String?,
         appVersion: String?,
         scanAt: String?,
         isTest: Bool?,
         planJson: PlanResponse?,
         completedSteps: [Int]?,
         currentStepIndex: Int?,
         previewStatus: String?,
         previewMeta: [String: AnyCodable]?,
         isDemo: Bool?,
         photoUrl: String?,
         metadata: ProjectMetadata? = nil) {
        self.id = id
        self.userId = userId
        self.name = name
        self.goal = goal
        self.budget = budget
        self.budgetTier = budgetTier
        self.skillLevel = skillLevel
        self.status = status
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.previewUrl = previewUrl
        self.inputImageUrl = inputImageUrl
        self.arProvider = arProvider
        self.arConfidence = arConfidence
        self.scalePxPerIn = scalePxPerIn
        self.calibrationMethod = calibrationMethod
        self.referenceObject = referenceObject
        self.roomType = roomType
        self.scanJson = scanJson
        self.dimensionsJson = dimensionsJson
        self.floorplanSvg = floorplanSvg
        self.deviceModel = deviceModel
        self.osVersion = osVersion
        self.appVersion = appVersion
        self.scanAt = scanAt
        self.isTest = isTest
        self.planJson = planJson
        self.completedSteps = completedSteps
        self.currentStepIndex = currentStepIndex
        self.previewStatus = previewStatus
        self.previewMeta = previewMeta
        self.isDemo = isDemo
        self.photoUrl = photoUrl
        self.metadata = metadata
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case userId
        case name
        case goal
        case budget
        case budgetTier
        case skillLevel
        case status
        case createdAt
        case updatedAt
        case previewUrl        = "preview_url"
        case inputImageUrl
        case arProvider
        case arConfidence
        case scalePxPerIn
        case calibrationMethod
        case referenceObject
        case roomType
        case scanJson
        case dimensionsJson
        case floorplanSvg
        case deviceModel
        case osVersion
        case appVersion
        case scanAt
        case isTest
        case planJson
        case completedSteps
        case currentStepIndex
        case previewStatus     = "preview_status"
        case previewMeta
        case isDemo
        case photoUrl
        case metadata
    }

    private enum LegacyCodingKeys: String, CodingKey {
        case id
        case userId              = "user_id"
        case name
        case goal
        case budget
        case budgetTier          = "budget_tier"
        case skillLevel          = "skill_level"
        case createdAt           = "created_at"
        case updatedAt           = "updated_at"
        case previewUrl          = "preview_url"
        case inputImageUrl       = "input_image_url"
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
        case photoUrl            = "photo_url"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let legacy = try? decoder.container(keyedBy: LegacyCodingKeys.self)

        id = try Project.decodeRequired(String.self, primary: container, primaryKey: .id, legacy: legacy, legacyKey: .id)
        userId = try Project.decodeRequired(String.self, primary: container, primaryKey: .userId, legacy: legacy, legacyKey: .userId)
        name = try Project.decodeRequired(String.self, primary: container, primaryKey: .name, legacy: legacy, legacyKey: .name)

        goal = try container.decodeIfPresent(String.self, forKey: .goal)
            ?? legacy?.decodeIfPresent(String.self, forKey: .goal)
        budget = try container.decodeIfPresent(String.self, forKey: .budget)
            ?? legacy?.decodeIfPresent(String.self, forKey: .budget)
        budgetTier = try container.decodeIfPresent(String.self, forKey: .budgetTier)
            ?? legacy?.decodeIfPresent(String.self, forKey: .budgetTier)
        skillLevel = try container.decodeIfPresent(String.self, forKey: .skillLevel)
            ?? legacy?.decodeIfPresent(String.self, forKey: .skillLevel)
        status = try container.decodeIfPresent(String.self, forKey: .status)

        createdAt = try container.decodeIfPresent(String.self, forKey: .createdAt)
            ?? legacy?.decodeIfPresent(String.self, forKey: .createdAt)
        updatedAt = try container.decodeIfPresent(String.self, forKey: .updatedAt)
            ?? legacy?.decodeIfPresent(String.self, forKey: .updatedAt)

        previewUrl = try container.decodeIfPresent(String.self, forKey: .previewUrl)
            ?? legacy?.decodeIfPresent(String.self, forKey: .previewUrl)
        inputImageUrl = try container.decodeIfPresent(String.self, forKey: .inputImageUrl)
            ?? legacy?.decodeIfPresent(String.self, forKey: .inputImageUrl)

        arProvider = try container.decodeIfPresent(String.self, forKey: .arProvider)
            ?? legacy?.decodeIfPresent(String.self, forKey: .arProvider)
        arConfidence = try container.decodeIfPresent(Double.self, forKey: .arConfidence)
            ?? legacy?.decodeIfPresent(Double.self, forKey: .arConfidence)
        scalePxPerIn = try container.decodeIfPresent(Double.self, forKey: .scalePxPerIn)
            ?? legacy?.decodeIfPresent(Double.self, forKey: .scalePxPerIn)
        calibrationMethod = try container.decodeIfPresent(String.self, forKey: .calibrationMethod)
            ?? legacy?.decodeIfPresent(String.self, forKey: .calibrationMethod)
        referenceObject = try container.decodeIfPresent(String.self, forKey: .referenceObject)
            ?? legacy?.decodeIfPresent(String.self, forKey: .referenceObject)
        roomType = try container.decodeIfPresent(String.self, forKey: .roomType)
            ?? legacy?.decodeIfPresent(String.self, forKey: .roomType)

        scanJson = try container.decodeIfPresent([String: AnyCodable].self, forKey: .scanJson)
            ?? legacy?.decodeIfPresent([String: AnyCodable].self, forKey: .scanJson)
        dimensionsJson = try container.decodeIfPresent([String: AnyCodable].self, forKey: .dimensionsJson)
            ?? legacy?.decodeIfPresent([String: AnyCodable].self, forKey: .dimensionsJson)
        floorplanSvg = try container.decodeIfPresent(String.self, forKey: .floorplanSvg)
            ?? legacy?.decodeIfPresent(String.self, forKey: .floorplanSvg)

        deviceModel = try container.decodeIfPresent(String.self, forKey: .deviceModel)
            ?? legacy?.decodeIfPresent(String.self, forKey: .deviceModel)
        osVersion = try container.decodeIfPresent(String.self, forKey: .osVersion)
            ?? legacy?.decodeIfPresent(String.self, forKey: .osVersion)
        appVersion = try container.decodeIfPresent(String.self, forKey: .appVersion)
            ?? legacy?.decodeIfPresent(String.self, forKey: .appVersion)
        scanAt = try container.decodeIfPresent(String.self, forKey: .scanAt)
            ?? legacy?.decodeIfPresent(String.self, forKey: .scanAt)

        isTest = try container.decodeIfPresent(Bool.self, forKey: .isTest)
            ?? legacy?.decodeIfPresent(Bool.self, forKey: .isTest)
        planJson = try container.decodeIfPresent(PlanResponse.self, forKey: .planJson)
            ?? legacy?.decodeIfPresent(PlanResponse.self, forKey: .planJson)
        completedSteps = try container.decodeIfPresent([Int].self, forKey: .completedSteps)
            ?? legacy?.decodeIfPresent([Int].self, forKey: .completedSteps)
        currentStepIndex = try container.decodeIfPresent(Int.self, forKey: .currentStepIndex)
            ?? legacy?.decodeIfPresent(Int.self, forKey: .currentStepIndex)
        previewStatus = try container.decodeIfPresent(String.self, forKey: .previewStatus)
            ?? legacy?.decodeIfPresent(String.self, forKey: .previewStatus)
        previewMeta = try container.decodeIfPresent([String: AnyCodable].self, forKey: .previewMeta)
            ?? legacy?.decodeIfPresent([String: AnyCodable].self, forKey: .previewMeta)
        isDemo = try container.decodeIfPresent(Bool.self, forKey: .isDemo)
            ?? legacy?.decodeIfPresent(Bool.self, forKey: .isDemo)
        photoUrl = try container.decodeIfPresent(String.self, forKey: .photoUrl)
            ?? legacy?.decodeIfPresent(String.self, forKey: .photoUrl)

        metadata = try container.decodeIfPresent(ProjectMetadata.self, forKey: .metadata)
    }
}

private extension Project {
    private static func decodeRequired<T: Decodable>(
        _ type: T.Type,
        primary: KeyedDecodingContainer<CodingKeys>,
        primaryKey: CodingKeys,
        legacy: KeyedDecodingContainer<LegacyCodingKeys>?,
        legacyKey: LegacyCodingKeys
    ) throws -> T {
        if let value = try primary.decodeIfPresent(T.self, forKey: primaryKey) {
            return value
        }
        if let value = try legacy?.decodeIfPresent(T.self, forKey: legacyKey) {
            return value
        }
        throw DecodingError.keyNotFound(
            primaryKey,
            DecodingError.Context(codingPath: primary.codingPath, debugDescription: "Missing required key \(primaryKey.rawValue)")
        )
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
                   previewMeta: [String: AnyCodable]? = nil,
                   metadata: ProjectMetadata? = nil) -> Project {
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
            previewUrl: previewURL ?? self.previewUrl,
            inputImageUrl: inputImageURL ?? self.inputImageUrl,
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
            isDemo: isDemo,
            photoUrl: photoUrl,
            metadata: metadata ?? self.metadata
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

struct ProjectMetadata: Codable, Equatable {
    let estimatedCost: Double?
    let materials: [String]?
    let estimatedDuration: String?
    let skillLevel: String?
    let area: Double?
    let perimeter: Double?
}
