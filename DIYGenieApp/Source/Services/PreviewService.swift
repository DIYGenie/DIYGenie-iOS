import Foundation

/// Lightweight compatibility wrapper so any legacy callers can still trigger
/// Decor8 previews without duplicating network logic. All preview requests now
/// flow through `ProjectsService.generatePreview(projectId:)` so payload casing
/// stays consistent with the backend.
final class PreviewService {
    static let shared = PreviewService()

    private let projectsService: ProjectsService

    init(userDefaults: UserDefaults = .standard, session: URLSession = .shared) {
        let identifier = userDefaults.string(forKey: "user_id") ?? UUID().uuidString
        if userDefaults.string(forKey: "user_id") == nil {
            userDefaults.set(identifier, forKey: "user_id")
        }
        self.projectsService = ProjectsService(userId: identifier, session: session)
    }

    /// Convenience async helper for SwiftUI/Combine callers.
    func requestPreview(for projectId: String) async throws -> Project {
        try await projectsService.generatePreview(projectId: projectId)
    }

    /// Legacy completion-based API retained for UIKit call sites.
    func requestPreview(
        for projectId: String,
        completion: @escaping (Result<Project, Error>) -> Void
    ) {
        Task {
            do {
                let project = try await projectsService.generatePreview(projectId: projectId)
                await MainActor.run {
                    completion(.success(project))
                }
            } catch {
                await MainActor.run {
                    completion(.failure(error))
                }
            }
        }
    }
}
