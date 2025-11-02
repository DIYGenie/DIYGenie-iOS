//
//  AnyCodable.swift
//  DIYGenieApp
//

import Foundation

// MARK: - AnyEncodable
public struct AnyEncodable: Encodable {
    private let encodeClosure: (Encoder) throws -> Void
    public init<T: Encodable>(_ value: T) { self.encodeClosure = value.encode }
    public func encode(to encoder: Encoder) throws { try encodeClosure(encoder) }
}

// MARK: - AnyCodable
public struct AnyCodable: Codable, Hashable {
    public let value: Any

    public init(_ value: Any) { self.value = value }

    public init(from decoder: Decoder) throws {
        let c = try decoder.singleValueContainer()
        if let v = try? c.decode(Bool.self)   { value = v }
        else if let v = try? c.decode(Int.self) { value = v }
        else if let v = try? c.decode(Double.self) { value = v }
        else if let v = try? c.decode(String.self) { value = v }
        else if let v = try? c.decode([String: AnyCodable].self) { value = v.mapValues { $0.value } }
        else if let v = try? c.decode([AnyCodable].self) { value = v.map { $0.value } }
        else {
            throw DecodingError.dataCorruptedError(in: c, debugDescription: "Unsupported AnyCodable type")
        }
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.singleValueContainer()
        switch value {
        case let v as Bool:   try c.encode(v)
        case let v as Int:    try c.encode(v)
        case let v as Double: try c.encode(v)
        case let v as String: try c.encode(v)
        case let v as [String: Any]:
            try c.encode(v.mapValues { AnyCodable($0) })
        case let v as [Any]:
            try c.encode(v.map { AnyCodable($0) })
        default:
            let ctx = EncodingError.Context(codingPath: encoder.codingPath,
                                            debugDescription: "Unsupported AnyCodable value")
            throw EncodingError.invalidValue(value, ctx)
        }
    }

    public static func == (lhs: AnyCodable, rhs: AnyCodable) -> Bool {
        switch (lhs.value, rhs.value) {
        case let (l as Bool,   r as Bool):   return l == r
        case let (l as Int,    r as Int):    return l == r
        case let (l as Double, r as Double): return l == r
        case let (l as String, r as String): return l == r
        case let (l as [String: Any], r as [String: Any]):
            return NSDictionary(dictionary: l).isEqual(to: r)
        case let (l as [Any], r as [Any]):
            return NSArray(array: l).isEqual(to: r)
        default: return false
        }
    }

    public func hash(into hasher: inout Hasher) {
        switch value {
        case let v as Bool:   hasher.combine(0); hasher.combine(v)
        case let v as Int:    hasher.combine(1); hasher.combine(v)
        case let v as Double: hasher.combine(2); hasher.combine(v.bitPattern)
        case let v as String: hasher.combine(3); hasher.combine(v)
        case let v as [String: Any]:
            hasher.combine(4)
            for k in v.keys.sorted() {
                hasher.combine(k)
                AnyCodable(v[k]!).hash(into: &hasher)
            }
        case let v as [Any]:
            hasher.combine(5)
            v.forEach { AnyCodable($0).hash(into: &hasher) }
        default:
            hasher.combine(6) // unknown
        }
    }
}

