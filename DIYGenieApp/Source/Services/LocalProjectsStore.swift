//
//  LocalProjectsStore.swift
//  DIYGenieApp
//
//  Lightweight persistence layer that mirrors the essential
//  behaviour of the production backend so the app can run
//  completely offline. Projects, photos, and AR scans are cached
//  to disk and surfaced through the same `ProjectsService` API.
//

import Foundation
import CoreGraphics

actor LocalProjectsStore {
    static let shared = LocalProjectsStore()

    enum StoreError: Error {
        case missingProject
        case failedToPersist
    }

    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    private let dateFormatter: ISO8601DateFormatter
    private let storageURL: URL
    private let attachmentsURL: URL
    private var projects: [Project] = []
    private let planGenerator = LocalPlanGenerator()

    private init() {
        let fm = FileManager.default
        let base = fm.urls(for: .documentDirectory, in: .userDomainMask).first ?? fm.temporaryDirectory
        let folder = base.appendingPathComponent("DIYGenie", isDirectory: true)
        let projectsURL = folder.appendingPathComponent("projects.json")
        storageURL = projectsURL
        attachmentsURL = folder.appendingPathComponent("attachments", isDirectory: true)

        encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted]
        decoder = JSONDecoder()
        dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        try? fm.createDirectory(at: attachmentsURL, withIntermediateDirectories: true)
        loadFromDisk()
    }

    // MARK: - CRUD
    func createProject(userId: String, name: String, goal: String, budget: String, skillLevel: String) throws -> Project {
        let now = timestamp()
        let project = Project(
            id: UUID().uuidString,
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
            isTest: true,
            planJson: nil,
            completedSteps: [],
            currentStepIndex: 0,
            previewStatus: "draft",
            previewMeta: nil,
            isDemo: true
        )

        projects.insert(project, at: 0)
        try persist()
        return project
    }

    func fetchProjects(for userId: String) -> [Project] {
        projects
            .filter { $0.userId == userId }
            .sorted { projectUpdatedDate($0) > projectUpdatedDate($1) }
    }

    func fetchProject(id: String) throws -> Project {
        guard let project = projects.first(where: { $0.id == id }) else {
            throw StoreError.missingProject
        }
        return project
    }

    // MARK: - Attachments
    func saveImage(projectId: String, data: Data) throws -> Project {
        let path = attachmentsURL.appendingPathComponent("\(projectId)-photo.jpg")
        try data.write(to: path, options: .atomic)
        return try update(projectId: projectId) { project in
            project.updating(
                updatedAt: timestamp(),
                inputImageURL: path.absoluteString,
                previewURL: project.previewURL ?? path.absoluteString,
                previewStatus: project.previewStatus ?? "photo_added"
            )
        }
    }

    func saveARScan(projectId: String, fileURL: URL) throws {
        let filename = "\(projectId)-scan.usdz"
        let destination = attachmentsURL.appendingPathComponent(filename)
        let data = try Data(contentsOf: fileURL)
        try data.write(to: destination, options: .atomic)

        _ = try update(projectId: projectId) { project in
            var meta = project.previewMeta ?? [:]
            meta["local_scan"] = AnyCodable([
                "file_url": destination.absoluteString,
                "filename": filename,
                "saved_at": timestamp()
            ])

            return project.updating(
                updatedAt: timestamp(),
                previewMeta: meta,
                scanJson: [
                    "local_file_url": AnyCodable(destination.absoluteString),
                    "filename": AnyCodable(filename)
                ],
                arProvider: "roomplan"
            )
        }
    }

    func saveCropRect(projectId: String, rect: CGRect) throws {
        _ = try update(projectId: projectId) { project in
            var meta = project.previewMeta ?? [:]
            let roi: [String: Any] = [
                "x": Double(rect.origin.x),
                "y": Double(rect.origin.y),
                "w": Double(rect.size.width),
                "h": Double(rect.size.height)
            ]
            meta["roi"] = AnyCodable(roi)

            return project.updating(
                updatedAt: timestamp(),
                previewMeta: meta
            )
        }
    }

    // MARK: - Plan generation
    func generatePlan(projectId: String, includePreview: Bool) throws -> Project {
        let project = try fetchProject(id: projectId)
        let plan = planGenerator.makePlan(for: project)
        let previewURL = includePreview ? (project.previewURL ?? project.inputImageURL) : project.previewURL
        let status = includePreview ? "preview_ready" : "plan_ready"

        return try update(projectId: projectId) { project in
            project.updating(
                updatedAt: timestamp(),
                previewURL: previewURL,
                planJson: plan,
                completedSteps: [],
                currentStepIndex: 0,
                previewStatus: status,
                previewMeta: mergedMeta(project.previewMeta, status: status)
            )
        }
    }

    // MARK: - Private helpers
    private func mergedMeta(_ meta: [String: AnyCodable]?, status: String) -> [String: AnyCodable] {
        var updated = meta ?? [:]
        updated["local_plan"] = AnyCodable([
            "generated_at": timestamp(),
            "status": status
        ])
        return updated
    }

    private func update(projectId: String, transform: (Project) -> Project) throws -> Project {
        guard let index = projects.firstIndex(where: { $0.id == projectId }) else {
            throw StoreError.missingProject
        }

        let updated = transform(projects[index])
        projects[index] = updated
        resort()
        try persist()
        return updated
    }

    private func resort() {
        projects.sort { projectUpdatedDate($0) > projectUpdatedDate($1) }
    }

    private func projectUpdatedDate(_ project: Project) -> Date {
        if let value = project.updatedAt, let date = dateFormatter.date(from: value) {
            return date
        }
        if let value = project.createdAt, let date = dateFormatter.date(from: value) {
            return date
        }
        return Date.distantPast
    }

    private func loadFromDisk() {
        guard FileManager.default.fileExists(atPath: storageURL.path) else { return }
        do {
            let data = try Data(contentsOf: storageURL)
            let decoded = try decoder.decode([Project].self, from: data)
            projects = decoded
            resort()
        } catch {
            print("⚠️ Failed to load local projects:", error)
        }
    }

    private func persist() throws {
        do {
            let data = try encoder.encode(projects)
            try data.write(to: storageURL, options: .atomic)
        } catch {
            throw StoreError.failedToPersist
        }
    }

    private func timestamp() -> String {
        dateFormatter.string(from: Date())
    }
}

extension LocalProjectsStore.StoreError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .missingProject:
            return "The project could not be found in local storage."
        case .failedToPersist:
            return "DIY Genie couldn't save your project data locally."
        }
    }
}

