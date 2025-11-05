//
//  PlanResponse.swift
//  DIYGenieApp
//

import Foundation

/// Full DIY plan returned by {API_BASE_URL}/api/projects/{id}/generate-plan
struct PlanResponse: Codable, Equatable {
    /// One-line or short paragraph summary for the plan.
    let summary: String?

    /// Ordered steps for the project.
    let steps: [Step]

    /// Materials list (strings or rich objects mapped to strings).
    let materials: [String]?

    /// Tools list.
    let tools: [String]?

    /// Human-readable cost (e.g., "$120–$180") if provided.
    let estimated_cost: String?

    /// Optional extra details from server — preserved for forward compatibility.
    let extras: [String: AnyCodable]?

    enum CodingKeys: String, CodingKey {
        case summary
        case steps
        case materials
        case tools
        case estimated_cost
        case extras
    }

    init(summary: String?,
         steps: [Step],
         materials: [String]?,
         tools: [String]?,
         estimated_cost: String?,
         extras: [String: AnyCodable]?) {
        self.summary = summary
        self.steps = steps
        self.materials = materials
        self.tools = tools
        self.estimated_cost = estimated_cost
        self.extras = extras
    }

    /// Be permissive with server JSON (strings or objects, missing keys, etc.)
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.summary = try c.decodeIfPresent(String.self, forKey: .summary)

        // Steps can be [String] or [{ "text": "...", ... }]
        if let rawStrings = try? c.decode([String].self, forKey: .steps) {
            self.steps = rawStrings.map { Step(text: $0) }
        } else if let rawObjects = try? c.decode([Step].self, forKey: .steps) {
            self.steps = rawObjects
        } else {
            self.steps = []
        }

        // Materials/tools may arrive as strings or objects. Normalize to [String].
        func normalizeStrings(for key: CodingKeys) -> [String]? {
            if let s = try? c.decode([String].self, forKey: key) { return s }
            if let anyArray = try? c.decode([AnyCodable].self, forKey: key) {
                let mapped = anyArray.compactMap { any -> String? in
                    switch any.value {
                    case let s as String: return s
                    case let d as [String: AnyCodable]:
                        // Prefer common fields if present
                        if let name = d["name"]?.value as? String { return name }
                        if let label = d["label"]?.value as? String { return label }
                        return nil
                    default:
                        return nil
                    }
                }
                return mapped.isEmpty ? nil : mapped
            }
            return nil
        }

        self.materials = normalizeStrings(for: .materials)
        self.tools = normalizeStrings(for: .tools)
        self.estimated_cost = try c.decodeIfPresent(String.self, forKey: .estimated_cost)

        // Capture any extra fields for forward compatibility.
        self.extras = try c.decodeIfPresent([String: AnyCodable].self, forKey: .extras)
    }
}

// MARK: - Step

extension PlanResponse {
    /// A single step in the plan. Decodes from either a string or an object.
    struct Step: Codable, Hashable, Identifiable, CustomStringConvertible {
        let id: UUID
        let text: String

        // Optional extra metadata (e.g., duration, warnings).
        let meta: [String: AnyCodable]?

        init(id: UUID = UUID(), text: String, meta: [String: AnyCodable]? = nil) {
            self.id = id
            self.text = text
            self.meta = meta
        }

        var description: String { text }

        enum CodingKeys: String, CodingKey {
            case id
            case text
            case meta
        }

        init(from decoder: Decoder) throws {
            // Accept either:
            // 1) "Install cleat on wall"
            // 2) { "id": "...", "text": "...", "meta": { ... } }
            let single = try? decoder.singleValueContainer()
            if let sc = single, let s = try? sc.decode(String.self) {
                self.id = UUID()
                self.text = s
                self.meta = nil
                return
            }

            let c = try decoder.container(keyedBy: CodingKeys.self)
            self.id = try c.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
            // Be tolerant: if "text" missing but there's another key, stringify it.
            if let t = try c.decodeIfPresent(String.self, forKey: .text) {
                self.text = t
            } else {
                // Fallback: reconstruct from entire object
                let raw = try AnyCodable(from: decoder)
                self.text = String(describing: raw.value)
            }
            self.meta = try c.decodeIfPresent([String: AnyCodable].self, forKey: .meta)
        }
    }
}
