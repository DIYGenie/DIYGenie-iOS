import Foundation

struct Project: Codable, Identifiable, Hashable {
    let id: String
    let title: String
    let description: String?
    let budget: String?
    let skillLevel: String?
    let lastUpdate: String?
    let previews: [Preview]?
    let createdAt: Date?
    let updatedAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case description
        case previews
        case createdAt
        case updatedAt
        case name
        case budget
        case budgetCents = "budget_cents"
        case skillLevel = "skill_level"
        case lastUpdate = "update"
    }
    
    init(id: String, title: String, description: String?, budget: String? = nil, skillLevel: String? = nil, lastUpdate: String? = nil, previews: [Preview]?, createdAt: Date?, updatedAt: Date?) {
        self.id = id
        self.title = title
        self.description = description
        self.budget = budget
        self.skillLevel = skillLevel
        self.lastUpdate = lastUpdate
        self.previews = previews
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        if let name = try container.decodeIfPresent(String.self, forKey: .name) {
            self.title = name
        } else if let t = try container.decodeIfPresent(String.self, forKey: .title) {
            self.title = t
        } else {
            self.title = ""
        }
        self.description = try container.decodeIfPresent(String.self, forKey: .description)
        // Decode budget as string first, fallback to mapping from budget_cents
        if let budgetString = try container.decodeIfPresent(String.self, forKey: .budget) {
            self.budget = budgetString
        } else if let cents = try container.decodeIfPresent(Int.self, forKey: .budgetCents) {
            if cents < 10_000 {
                self.budget = "$"
            } else if cents < 50_000 {
                self.budget = "$$"
            } else {
                self.budget = "$$$"
            }
        } else {
            self.budget = nil
        }
        self.skillLevel = try container.decodeIfPresent(String.self, forKey: .skillLevel)
        self.lastUpdate = try container.decodeIfPresent(String.self, forKey: .lastUpdate)
        self.previews = try container.decodeIfPresent([Preview].self, forKey: .previews)
        self.createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt)
        self.updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encodeIfPresent(description, forKey: .description)
        try container.encodeIfPresent(budget, forKey: .budget)
        try container.encodeIfPresent(skillLevel, forKey: .skillLevel)
        try container.encodeIfPresent(lastUpdate, forKey: .lastUpdate)
        try container.encodeIfPresent(previews, forKey: .previews)
        try container.encodeIfPresent(createdAt, forKey: .createdAt)
        try container.encodeIfPresent(updatedAt, forKey: .updatedAt)
    }
}

