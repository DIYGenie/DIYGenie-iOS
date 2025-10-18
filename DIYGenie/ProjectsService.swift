import Foundation

struct ProjectsService {
    private let api = APIClient.shared

    func fetchProjects() async throws -> [Project] {
        do {
            return try await api.get("/api/projects", query: [URLQueryItem(name: "user_id", value: UserSession.shared.userId)])
        } catch {
            struct ProjectsEnvelope: Decodable { let ok: Bool?; let projects: [Project]?; let data: [Project]? }
            do {
                let envelope: ProjectsEnvelope = try await api.get("/api/projects", query: [URLQueryItem(name: "user_id", value: UserSession.shared.userId)])
                return envelope.projects ?? envelope.data ?? []
            } catch {
                throw error
            }
        }
    }

    func deleteProject(id: String) async throws -> BoolResponse {
        try await api.delete("/api/projects/\(id)")
    }

    @discardableResult
    func createProject(title: String, goal: String) async throws -> Project {
        let ts = Int(Date().timeIntervalSince1970)
        let safe = "iOS Debug \(ts)" // unique, alphanumeric + space

        struct Body: Encodable { // dollars fallback
            let name: String
            let goal: String
            let user_id: String
            let client: String
            let budget: Int
            let currency: String
        }
        struct BodyCents: Encodable { // cents fallback
            let name: String
            let goal: String
            let user_id: String
            let client: String
            let budget_cents: Int
            let currency: String
        }

        let initialBody = Body(
            name: safe,
            goal: goal.isEmpty ? "smoke test" : goal,
            user_id: UserSession.shared.userId,
            client: "ios",
            budget: 0,
            currency: "USD"
        )

        // Helper to pretty-print JSON
        func jsonString<T: Encodable>(_ value: T) -> String {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            do { return String(data: try encoder.encode(value), encoding: .utf8) ?? "<non-utf8>" } catch { return "<encode failed: \(error)>" }
        }

        do {
            return try await api.post("/api/projects", body: initialBody)
        } catch {
            // Log request and response
            print("REQUEST JSON:")
            print(jsonString(initialBody))
            if case let APIError.httpError(status, body) = error {
                print("RAW RESPONSE (status \(status)):\n\(body)")
                // If server hints at budget_cents, retry with cents version
                if status >= 400 && body.lowercased().contains("budget_cents") {
                    let centsBody = BodyCents(
                        name: initialBody.name,
                        goal: initialBody.goal,
                        user_id: initialBody.user_id,
                        client: initialBody.client,
                        budget_cents: 0,
                        currency: initialBody.currency
                    )
                    print("Retrying with budget_cents…")
                    print("REQUEST JSON (retry):")
                    print(jsonString(centsBody))
                    do {
                        return try await api.post("/api/projects", body: centsBody)
                    } catch {
                        if case let APIError.httpError(status2, body2) = error {
                            print("RAW RESPONSE (retry) (status \(status2)):\n\(body2)")
                        }
                        throw error
                    }
                }
            }
            throw error
        }
    }
}

struct BoolResponse: Codable { let success: Bool }
