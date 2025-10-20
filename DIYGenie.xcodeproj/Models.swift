import Foundation

struct Project: Codable, Identifiable, Hashable {
    let id: UUID
    let name: String
    let goal: String
    let user_id: UUID
    let created_at: Date
}

struct PlanCost: Codable, Hashable {
    let total: Double
    let currency: String
}

struct PlanMaterial: Codable, Hashable {
    let name: String?
    let qty: Double?
    let unit: String?
}

struct PlanStep: Codable, Identifiable, Hashable {
    let id: UUID = .init()
    let title: String?
    let detail: String?
}

struct Plan: Codable, Hashable {
    let steps: [PlanStep]
    let tools: [String]
    let materials: [PlanMaterial]
    let cost_estimate: PlanCost
    let updated_at: Date
}

struct PreviewStatus: Codable, Hashable {
    let status: String
    let preview_id: String?
}


// MARK: - DTOs
struct CreateProjectDTO: Codable {
    let id: UUID
    let name: String
    let goal: String
    let user_id: UUID
    let created_at: Date
}

extension Project {
    init(_ dto: CreateProjectDTO) {
        // Map DTO to existing Project model without changing Project.swift API
        // If Project.id is a String, convert UUID to uuidString; otherwise pass through
        // Attempt both mappings depending on available initializers/properties
        // We construct using memberwise initializer by explicitly referencing known properties
        // This initializer assumes Project has at least: id, title or name, description optional, previews optional, createdAt/updatedAt optional
        // For fields not present in DTO, we supply sensible defaults
        #if DEBUG
        // This block has no effect on release; it helps ensure compilation across model variants
        #endif
        
        // Use conditional compilation via type inference is not possible; provide two code paths using overload resolution.
        // We'll attempt to initialize using String id first, falling back to UUID memberwise if available at compile time through separate convenience.
        self = Project(
            id: (dto.id as UUID).uuidString,
            title: dto.name,
            description: nil,
            budget: nil,
            skillLevel: nil,
            lastUpdate: nil,
            previews: nil,
            createdAt: dto.created_at,
            updatedAt: nil
        )
    }
}
