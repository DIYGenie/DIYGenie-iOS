//
//  PlanResponse.swift
//  DIYGenieApp
//
//  Full DIY plan returned by your backend.
//  Tolerant to key variants: `estimated_cost` or `estimated_total`.
//

import Foundation

public struct PlanResponse: Codable, Hashable {
    public var summary: String?
    public var steps: [String]
    public var materials: [String]
    public var tools: [String]
    public var estimatedCost: Double?   // USD total

    public init(
        summary: String? = nil,
        steps: [String] = [],
        materials: [String] = [],
        tools: [String] = [],
        estimatedCost: Double? = nil
    ) {
        self.summary = summary
        self.steps = steps
        self.materials = materials
        self.tools = tools
        self.estimatedCost = estimatedCost
    }

    private enum CodingKeys: String, CodingKey {
        case summary
        case steps
        case materials
        case tools
        // primary write key
        case estimatedCost = "estimated_cost"
        // tolerant read alias
        case estimatedTotal = "estimated_total"
    }

    // Custom decode so we accept either cost key.
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        summary = try c.decodeIfPresent(String.self, forKey: .summary)
        steps = try c.decodeIfPresent([String].self, forKey: .steps) ?? []
        materials = try c.decodeIfPresent([String].self, forKey: .materials) ?? []
        tools = try c.decodeIfPresent([String].self, forKey: .tools) ?? []
        if let v = try c.decodeIfPresent(Double.self, forKey: .estimatedCost) {
            estimatedCost = v
        } else {
            estimatedCost = try c.decodeIfPresent(Double.self, forKey: .estimatedTotal)
        }
    }

    // Custom encode so we always write `estimated_cost`.
    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encodeIfPresent(summary, forKey: .summary)
        if !steps.isEmpty { try c.encode(steps, forKey: .steps) }
        if !materials.isEmpty { try c.encode(materials, forKey: .materials) }
        if !tools.isEmpty { try c.encode(tools, forKey: .tools) }
        try c.encodeIfPresent(estimatedCost, forKey: .estimatedCost)
    }
}
