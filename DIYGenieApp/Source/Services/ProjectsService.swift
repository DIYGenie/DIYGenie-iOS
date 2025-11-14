//
//  ProjectsService.swift
//  DIYGenieApp
//

import Foundation
import UIKit

/// Lightweight in-memory implementation so the app can build and run UI flows
/// without talking to the real backend. Swap this out with your Supabase/API
/// implementation later.
struct ProjectsService {
    let userId: String

    // Simple shared store so projects survive within one app session.
    private static var store: [String: Project] = [:]

    // MARK: - Create
    func createProject(name: String, goal: String, budget: String, skillLevel: String) async throws -> Project {
        let id = UUID().uuidString
        let project = Project(
            id: id,
            userId: userId,
            name: name,
            goal: goal,
            budget: budget,
            budgetTier: nil,
            skillLevel: skillLevel,
            status: "draft",
            createdAt: nil,
            updatedAt: nil,
            preview_url: nil,
            input_image_url: nil,
            arProvider: nil,
            arConfidence: nil,
            scalePxPerIn: nil,
            calibrationMethod: nil,
            referenceObject: nil,
            roomType: nil,
            scanJson: nil,
            dimensionsJson: nil,
            floorplanSvg: nil,
            deviceModel: nil,
            osVersion: nil,
            appVersion: nil,
            scanAt: nil,
            isTest: nil,
            planJson: nil,
            completedSteps: nil,
            currentStepIndex: nil,
            previewStatus: nil,
            previewMeta: nil,
            isDemo: nil
        )
        Self.store[id] = project
        return project
    }

    // MARK: - Images / AR (no-op in in-memory mode)
    func uploadImage(projectId: String, image: UIImage) async throws {
        // In a real implementation you would upload the image and update preview/input URLs.
    }

    func uploadARScan(projectId: String, fileURL: URL) async throws {
        // In a real implementation you would upload the RoomPlan USDZ/JSON here.
    }

    // MARK: - Plan generation (no-op stubs)
    func generatePreview(projectId: String) async throws {
        // Call your backend to create a Decor8 preview + plan; noop for now.
    }

    func generatePlanOnly(projectId: String) async throws {
        // Call your backend to create a text-only plan; noop for now.
    }

    // MARK: - Optional crop rect (disabled)
    func attachCropRectIfAvailable(projectId: String, rect: CGRect) async {
        // Intentionally left blank in the in-memory implementation.
    }

    // MARK: - Fetch
    func fetchProjects() async throws -> [Project] {
        Array(Self.store.values)
    }

    func fetchProject(projectId: String) async throws -> Project {
        guard let project = Self.store[projectId] else {
            throw NSError(domain: "ProjectsService", code: 404, userInfo: [NSLocalizedDescriptionKey: "Project not found"])
        }
        return project
    }
}
