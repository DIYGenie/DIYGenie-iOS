//
//  PlanResponse.swift
//  DIYGenie
//
//  Created by Tye on 11/16/24.
//  Clean, self-contained model for AI plan responses.
//

import Foundation

/// Top–level response returned by the AI “generate plan” endpoint.
/// This is intentionally flexible so small JSON changes don’t break decoding.
struct PlanResponse: Codable {
    /// Optional project identifier (if your backend sends it back)
    let projectId: String?

    /// High-level summary of the project (ex: “Paint kitchen cabinets and replace hardware”)
    let summary: String?

    /// Human-readable estimated total cost (ex: “$450–$650”)
    let estimatedCost: String?

    /// Human-readable duration (ex: “Weekend project (1–2 days)”)
    let estimatedDuration: String?

    /// Suggested skill level (ex: “Beginner”, “Intermediate”, “Advanced”)
    let skillLevel: String?

    /// Ordered list of steps to complete the project
    let steps: [PlanStep]

    /// Materials to purchase (wood, paint, screws, etc.)
    let materials: [PlanMaterial]

    /// Tools required for the project (drill, miter saw, etc.)
    let tools: [PlanTool]

    /// Optional structured cost breakdown per section/category
    let costBreakdown: [PlanCostItem]?

    /// Optional additional notes or safety call-outs
    let notes: String?

    enum CodingKeys: String, CodingKey {
        case projectId
        case summary
        case estimatedCost
        case estimatedDuration
        case skillLevel
        case steps
        case materials
        case tools
        case costBreakdown
        case notes
    }

    private enum LegacyCodingKeys: String, CodingKey {
        case projectIdSnake = "project_id"
    }

    /// Provide safe fallbacks if the API ever omits arrays
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let legacy = try? decoder.container(keyedBy: LegacyCodingKeys.self)

        let camelId = try container.decodeIfPresent(String.self, forKey: .projectId)
        let snakeId = try legacy?.decodeIfPresent(String.self, forKey: .projectIdSnake)
        projectId         = camelId ?? snakeId
        summary           = try container.decodeIfPresent(String.self, forKey: .summary)
        estimatedCost     = try container.decodeStringOrNumber(forKey: .estimatedCost)
        estimatedDuration = try container.decodeStringOrNumber(forKey: .estimatedDuration)
        skillLevel        = try container.decodeIfPresent(String.self, forKey: .skillLevel)
        notes             = try container.decodeIfPresent(String.self, forKey: .notes)
        costBreakdown     = try container.decodeIfPresent([PlanCostItem].self, forKey: .costBreakdown)

        steps     = try container.decodeIfPresent([PlanStep].self, forKey: .steps)     ?? []
        materials = try container.decodeIfPresent([PlanMaterial].self, forKey: .materials) ?? []
        tools     = try container.decodeIfPresent([PlanTool].self, forKey: .tools)     ?? []
    }

    /// Convenience init for previews/tests
    init(
        projectId: String? = nil,
        summary: String? = nil,
        estimatedCost: String? = nil,
        estimatedDuration: String? = nil,
        skillLevel: String? = nil,
        steps: [PlanStep] = [],
        materials: [PlanMaterial] = [],
        tools: [PlanTool] = [],
        costBreakdown: [PlanCostItem]? = nil,
        notes: String? = nil
    ) {
        self.projectId = projectId
        self.summary = summary
        self.estimatedCost = estimatedCost
        self.estimatedDuration = estimatedDuration
        self.skillLevel = skillLevel
        self.steps = steps
        self.materials = materials
        self.tools = tools
        self.costBreakdown = costBreakdown
        self.notes = notes
    }
}

// MARK: - Steps

struct PlanStep: Codable, Identifiable, Hashable {
    /// Stable identifier for SwiftUI lists – falls back to `order` if present.
    var id: Int { order ?? localId }

    /// Local fallback id (not part of the JSON)
    private let localId: Int

    /// Order/sequence number of the step (1, 2, 3…)
    let order: Int?

    /// Short title (ex: “Prep and clean surfaces”)
    let title: String

    /// Detailed instructions for the step
    let details: String?

    /// Optional estimated time for this step (ex: “1–2 hours”)
    let estimatedTime: String?

    enum CodingKeys: String, CodingKey {
        case order
        case title
        case details
        case estimatedTime
    }

    init(
        order: Int? = nil,
        title: String,
        details: String? = nil,
        estimatedTime: String? = nil
    ) {
        self.order = order
        self.title = title
        self.details = details
        self.estimatedTime = estimatedTime
        self.localId = Int.random(in: 1...1_000_000)
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        order         = try container.decodeIfPresent(Int.self, forKey: .order)
        title         = try container.decodeIfPresent(String.self, forKey: .title) ?? "Step"
        details       = try container.decodeIfPresent(String.self, forKey: .details)
        estimatedTime = try container.decodeIfPresent(String.self, forKey: .estimatedTime)
        localId       = Int.random(in: 1...1_000_000)
    }
}

// MARK: - Materials

struct PlanMaterial: Codable, Identifiable, Hashable {
    var id: UUID { UUID() }

    /// Material name (ex: “1x4 pine board”)
    let name: String

    /// Quantity / unit (ex: “4 boards (8 ft)”, “1 gallon”)
    let quantity: String?

    /// Optional notes (ex: “Semi-gloss, interior, low-VOC”)
    let notes: String?

    enum CodingKeys: String, CodingKey {
        case name
        case quantity
        case notes
    }
}

// MARK: - Tools

struct PlanTool: Codable, Identifiable, Hashable {
    var id: UUID { UUID() }

    /// Tool name (ex: “Drill/driver”)
    let name: String

    /// Optional notes (ex: “Optional but recommended”, “Can rent from Home Depot”)
    let notes: String?

    enum CodingKeys: String, CodingKey {
        case name
        case notes
    }
}

// MARK: - Cost breakdown (optional)

struct PlanCostItem: Codable, Identifiable, Hashable {
    var id: UUID { UUID() }

    /// Category or label (ex: “Lumber”, “Paint & finishes”, “Hardware”)
    let category: String

    /// Human-friendly price (ex: “$150–$200”)
    let amount: String

    /// Optional extra detail
    let notes: String?

    enum CodingKeys: String, CodingKey {
        case category
        case amount
        case notes
    }

    init(category: String, amount: String, notes: String?) {
        self.category = category
        self.amount = amount
        self.notes = notes
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.category = try container.decode(String.self, forKey: .category)
        // Decode amount as string or number, defaulting to an empty string if missing
        let decodedAmount = try container.decodeStringOrNumber(forKey: .amount) ?? ""
        self.amount = decodedAmount
        self.notes = try container.decodeIfPresent(String.self, forKey: .notes)
    }
}

// MARK: - Helpers

extension Array where Element == PlanStep {
    /// Returns the steps sorted by their optional `order`, while also preserving
    /// the original index. The original index is useful for matching existing
    /// completion state stored in Supabase.
    func orderedWithOriginalIndices() -> [(originalIndex: Int, step: PlanStep)] {
        enumerated()
            .sorted { lhs, rhs in
                let lhsOrder = lhs.element.order ?? Int.max
                let rhsOrder = rhs.element.order ?? Int.max
                if lhsOrder == rhsOrder {
                    return lhs.offset < rhs.offset
                }
                return lhsOrder < rhsOrder
            }
            .map { (originalIndex: $0.offset, step: $0.element) }
    }
}

private extension KeyedDecodingContainer {
    /// Decodes a value that may be a String, Int, or Double and returns it as a String.
    /// If the key is missing or the value can't be decoded as any of those types, returns nil.
    func decodeStringOrNumber(forKey key: Key) throws -> String? {
        if let s = try? decode(String.self, forKey: key) { return s }
        if let i = try? decode(Int.self, forKey: key) { return String(i) }
        if let d = try? decode(Double.self, forKey: key) {
            // Trim trailing .0 for whole numbers, otherwise keep up to 2 decimals
            if d.rounded() == d {
                return String(Int(d))
            } else {
                return String(format: "%.2f", d)
            }
        }
        return nil
    }
}
