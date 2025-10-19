import Foundation

struct ProjectsListResponse: Decodable {
    let ok: Bool
    let items: [Project]
}

struct ProjectCreateRequest: Encodable {
    let name: String
    let goal: String
    let user_id: String
    let client: String
    let budget: String
    let skill_level: String
    let update: String
}

struct ProjectCreateResponse: Decodable {
    let ok: Bool
    let item: ProjectMinimal
}

struct ProjectMinimal: Decodable {
    let id: String
    let status: String
}

struct ProjectsService {
    private let api = APIClient.shared
    static let shared = ProjectsService()

    private func budgetSymbol(_ b: BudgetTier) -> String {
        switch b {
        case .one: return "$"
        case .two: return "$$"
        case .three: return "$$$"
        default: return "$" // fallback for any extended tiers
        }
    }

    func list(userId: String) async throws -> [Project] {
        do {
            let resp: ProjectsListResponse = try await api.get(
                "/api/projects",
                query: [URLQueryItem(name: "user_id", value: userId)]
            )
            return resp.items
        } catch {
            throw error
        }
    }

    func deleteProject(id: String) async throws -> BoolResponse {
        try await api.delete("/api/projects/\(id)")
    }

    func create(name: String,
                goal: String,
                budget: BudgetTier = .one,
                skill: SkillLevel = .beginner,
                update: String = "created from iOS",
                userId: String) async throws -> ProjectMinimal {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 10 else { throw APIError.invalidRequest("name must be at least 10 characters") }

        let body = ProjectCreateRequest(
            name: trimmed,
            goal: goal,
            user_id: userId,
            client: "ios",
            budget: budgetSymbol(budget),
            skill_level: skill.rawValue,
            update: update
        )

        print("[ProjectsService#create v2] building request…")
        do {
            let resp: ProjectCreateResponse = try await api.post("/api/projects", body: body)
            return resp.item
        } catch {
            // Print request and raw response if available
            print("REQUEST JSON:", String(data: try! JSONEncoder().encode(body), encoding: .utf8)!)
            if case let APIError.httpError(status, responseBody) = error {
                print("RAW RESPONSE (status \(status)):\n\(responseBody)")
            }
            throw error
        }
    }
}

struct BoolResponse: Codable { let success: Bool }
