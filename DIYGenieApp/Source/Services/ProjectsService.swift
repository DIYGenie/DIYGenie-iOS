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
    private static let isoFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    // MARK: - Create
    func createProject(name: String, goal: String, budget: String, skillLevel: String) async throws -> Project {
        let id = UUID().uuidString
        let now = Self.isoFormatter.string(from: Date())
        let project = Project(
            id: id,
            userId: userId,
            name: name,
            goal: goal,
            budget: budget,
            budgetTier: nil,
            skillLevel: skillLevel,
            status: "draft",
            createdAt: now,
            updatedAt: now,
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
            previewStatus: "not_requested",
            previewMeta: nil,
            isDemo: nil
        )
        Self.store[id] = project
        return project
    }

    // MARK: - Images / AR (no-op in in-memory mode)
    func uploadImage(projectId: String, image: UIImage) async throws {
        let url = try persist(image: image, for: projectId)
        try updateProject(projectId) { project in
            let now = Self.isoFormatter.string(from: Date())
            return project.replacing(
                updatedAt: now,
                inputImageURL: url.absoluteString
            )
        }
    }

    func uploadARScan(projectId: String, fileURL: URL) async throws {
        // In a real implementation you would upload the RoomPlan USDZ/JSON here.
    }

    // MARK: - Plan generation (no-op stubs)
    func generatePreview(projectId: String) async throws {
        try updateProject(projectId) { project in
            let now = Self.isoFormatter.string(from: Date())
            let plan = samplePlan(for: project)
            return project.replacing(
                updatedAt: now,
                previewURL: project.preview_url ?? placeholderPreviewURL(for: project.id),
                planJson: plan,
                completedSteps: [],
                currentStepIndex: 0,
                previewStatus: "ready"
            )
        }
    }

    func generatePlanOnly(projectId: String) async throws {
        try updateProject(projectId) { project in
            let now = Self.isoFormatter.string(from: Date())
            let plan = samplePlan(for: project)
            return project.replacing(
                updatedAt: now,
                planJson: plan,
                completedSteps: [],
                currentStepIndex: 0,
                previewStatus: "plan_ready"
            )
        }
    }

    // MARK: - Optional crop rect (disabled)
    func attachCropRectIfAvailable(projectId: String, rect: CGRect) async {
        // Intentionally left blank in the in-memory implementation.
    }

    // MARK: - Fetch
    func fetchProjects() async throws -> [Project] {
        let values = Array(Self.store.values)
        return values.sorted { lhs, rhs in
            let lhsDate = Self.parseDate(lhs.updatedAt) ?? Self.parseDate(lhs.createdAt) ?? .distantPast
            let rhsDate = Self.parseDate(rhs.updatedAt) ?? Self.parseDate(rhs.createdAt) ?? .distantPast
            return lhsDate > rhsDate
        }
    }

    func fetchProject(projectId: String) async throws -> Project {
        guard let project = Self.store[projectId] else {
            throw NSError(domain: "ProjectsService", code: 404, userInfo: [NSLocalizedDescriptionKey: "Project not found"])
        }
        return project
    }
}

// MARK: - Private helpers
private extension ProjectsService {
    static func parseDate(_ string: String?) -> Date? {
        guard let string else { return nil }
        return isoFormatter.date(from: string)
    }

    func updateProject(_ projectId: String, builder: (Project) -> Project) throws {
        guard let existing = Self.store[projectId] else {
            throw NSError(domain: "ProjectsService", code: 404, userInfo: [NSLocalizedDescriptionKey: "Project not found"])
        }
        Self.store[projectId] = builder(existing)
    }

    func persist(image: UIImage, for projectId: String) throws -> URL {
        guard let data = image.jpegData(compressionQuality: 0.85) else {
            throw NSError(domain: "ProjectsService", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid image data"])
        }

        let url = Self.localImageURL(for: projectId)
        try data.write(to: url, options: .atomic)
        return url
    }

    static func localImageURL(for projectId: String) -> URL {
        let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first ?? FileManager.default.temporaryDirectory
        return caches.appendingPathComponent("project-\(projectId).jpg")
    }

    func placeholderPreviewURL(for projectId: String) -> String {
        // Deterministic remote placeholder to mimic Decor8 preview output
        return "https://images.unsplash.com/photo-1505692794403-55b39e8e5f6b?auto=format&fit=crop&w=1200&q=80&sig=\(projectId.hashValue)"
    }

    func samplePlan(for project: Project) -> PlanResponse {
        let name = project.name
        return PlanResponse(
            summary: "Custom build plan for \(name)",
            steps: [
                "Review the existing space and clear the working area.",
                "Measure twice and mark stud locations along the wall.",
                "Cut materials to size, dry-fit, then fasten securely.",
                "Finish with sanding, paint or stain, and final styling."
            ],
            materials: [
                "1x8 pine boards", "2\" wood screws", "Stud finder", "Wall anchors"
            ],
            tools: [
                "Impact driver", "Level", "Measuring tape", "Orbital sander"
            ],
            estimatedCost: 225
        )
    }
}
