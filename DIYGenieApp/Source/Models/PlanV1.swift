//
//  PlanV1.swift
//  DIYGenieApp
//
//  New plan model for the generate-plan endpoint.
//

import Foundation

struct PlanV1: Codable, Identifiable, Hashable {
    let id: UUID
    let projectId: UUID
    let summary: String?
    let overview: String?
    let steps: [Step]
    let tools: [PlanItem]
    let materials: [PlanItem]
    let cuts: [Cut]
    let cost: Cost?
    let previewUrl: URL?
    
    enum CodingKeys: String, CodingKey {
        case id
        case projectId = "project_id"
        case summary
        case overview
        case steps
        case tools
        case materials
        case cuts
        case cost
        case previewUrl = "preview_url"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        
        // Handle projectId as UUID or String
        if let projectIdUUID = try? container.decode(UUID.self, forKey: .projectId) {
            projectId = projectIdUUID
        } else if let projectIdString = try? container.decode(String.self, forKey: .projectId),
                  let projectIdUUID = UUID(uuidString: projectIdString) {
            projectId = projectIdUUID
        } else {
            throw DecodingError.keyNotFound(
                CodingKeys.projectId,
                DecodingError.Context(codingPath: container.codingPath, debugDescription: "Missing or invalid project_id")
            )
        }
        summary = try container.decodeIfPresent(String.self, forKey: .summary)
        overview = try container.decodeIfPresent(String.self, forKey: .overview)
        steps = try container.decodeIfPresent([Step].self, forKey: .steps) ?? []
        tools = try container.decodeIfPresent([PlanItem].self, forKey: .tools) ?? []
        materials = try container.decodeIfPresent([PlanItem].self, forKey: .materials) ?? []
        cuts = try container.decodeIfPresent([Cut].self, forKey: .cuts) ?? []
        cost = try container.decodeIfPresent(Cost.self, forKey: .cost)
        
        if let previewUrlString = try container.decodeIfPresent(String.self, forKey: .previewUrl),
           let url = URL(string: previewUrlString) {
            previewUrl = url
        } else {
            previewUrl = nil
        }
    }
}

// MARK: - Step

struct Step: Codable, Identifiable, Hashable {
    let id: UUID
    let title: String
    let details: String?
    let durationMinutes: Int?
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case details
        case durationMinutes = "duration_minutes"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        title = try container.decode(String.self, forKey: .title)
        details = try container.decodeIfPresent(String.self, forKey: .details)
        durationMinutes = try container.decodeIfPresent(Int.self, forKey: .durationMinutes)
    }
}

// MARK: - PlanItem

struct PlanItem: Codable, Identifiable, Hashable {
    let id: UUID
    let name: String
    let quantity: Double?
    let unit: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case quantity
        case unit
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        name = try container.decode(String.self, forKey: .name)
        quantity = try container.decodeIfPresent(Double.self, forKey: .quantity)
        unit = try container.decodeIfPresent(String.self, forKey: .unit)
    }
}

// MARK: - Cut

struct Cut: Codable, Identifiable, Hashable {
    let id: UUID
    let description: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case description
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        description = try container.decode(String.self, forKey: .description)
    }
}

// MARK: - Cost

struct Cost: Codable, Hashable {
    let materialsSubtotal: Double?
    let toolsSubtotal: Double?
    let contingencyPercent: Double?
    let total: Double?
    
    enum CodingKeys: String, CodingKey {
        case materialsSubtotal = "materials_subtotal"
        case toolsSubtotal = "tools_subtotal"
        case contingencyPercent = "contingency_percent"
        case total
    }
}

