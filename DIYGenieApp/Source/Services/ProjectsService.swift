import Foundation

final class ProjectsService {
    static let shared = ProjectsService()
    private init() {}

    /// Creates a new project via backend webhook and returns the project ID.
    func createProject(
        name: String,
        goal: String,
        budget: String,
        skillLevel: String,
        imagePath: String,
        measuredWidthInches: Double,
        measuredHeightInches: Double,
        wantsPreview: Bool
    ) async throws -> String {
        // API base from your config
        guard let baseURL = URL(string: "https://api.diygenieapp.com/api/projects") else {
            throw URLError(.badURL)
        }

        // Prepare request body
        let payload: [String: Any] = [
            "name": name,
            "goal": goal,
            "budget": budget,
            "skill_level": skillLevel,
            "image_url": imagePath,
            "measured_width": measuredWidthInches,
            "measured_height": measuredHeightInches,
            "wants_preview": wantsPreview
        ]

        var request = URLRequest(url: baseURL)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)

        // Perform request
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode)
        else {
            let body = String(data: data, encoding: .utf8) ?? ""
            throw NSError(domain: "ProjectsService", code: 1, userInfo: [
                NSLocalizedDescriptionKey: "Request failed: \(response)"
            ])
        }

        // Parse project ID
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let projectId = json?["id"] as? String ?? UUID().uuidString
        return projectId
    }
}
