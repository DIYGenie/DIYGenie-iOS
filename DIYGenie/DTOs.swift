import Foundation

// MARK: - Health
struct HealthDTO: Decodable {
    let ok: Bool
    let ts: Date
    let version: String
}

// MARK: - Create Project
struct CreateProjectBody: Encodable {
    let name: String
    let goal: String
    let user_id: UUID
    let client: String
    let budget: Double
    let skill_level: String
}

// Use the SAME name your list currently decodes to (e.g., CreateProjectDTO or Project)
// Full replacement for that struct:
struct CreateProjectDTO: Decodable, Identifiable {
    let id: UUID
    let name: String
    let status: String
    // Backend list doesn’t include goal; make it optional.
    let goal: String?
    // These are present (may be null) in your RAW JSON.
    let inputImageURL: URL?
    let previewURL: URL?
}
// ✅ Ready to Build
// MARK: - Projects List
struct ProjectsListResponse: Decodable {
    let ok: Bool
    let items: [ProjectSummaryDTO]
}

struct ProjectSummaryDTO: Decodable, Identifiable {
    let id: UUID
    let name: String
    let status: String
    let inputImageURL: URL?
    let previewURL: URL?
    // Backend list payload doesn’t include this currently; make it optional.
    let goal: String?
}
// ✅ Ready to Build
// MARK: - Preview
struct PreviewStatus: Decodable {
    let status: String
    let previewId: String?
}

// MARK: - Plan
struct PlanCost: Decodable {
    let total: Double
    let currency: String
}

struct PlanMaterial: Decodable {
    let name: String?
    let qty: Double?
    let unit: String?
}

struct PlanStep: Decodable, Identifiable {
    var id = UUID()
    let title: String?
    let detail: String?
}

struct Plan: Decodable {
    let steps: [PlanStep]
    let tools: [String]
    let materials: [PlanMaterial]
    let costEstimate: PlanCost
    let updatedAt: Date
}

// MARK: - Generic small responses
struct BoolResponse: Decodable { let ok: Bool }
