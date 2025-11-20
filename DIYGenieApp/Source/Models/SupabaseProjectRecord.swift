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
    let photoUrl: String?

    let previewPasses: [SupabasePreviewPassRecord]?
    let profiles: SupabaseProfileRecord?

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
