//
//  AnyCodable.swift
//  DIYGenieApp
//

import Foundation

// MARK: - AnyEncodable
/// Type-erases an Encodable so it can live inside heterogenous payloads,
/// e.g. `[String: AnyEncodable]`.
public struct AnyEncodable: Encodable {
    private let _encode: (Encoder) throws -> Void

    public init<T: Encodable>(_ value: T) {
        self._encode = value.encode
    }

    public func encode(to encoder: Encoder) throws {
        try _encode(encoder)
    }
}

// MARK: - AnyCodable
/// Minimal, JSON-safe type eraser for Codable values.
/// Supported payloads:
/// - String, Bool, Int, Double
/// - [AnyCodable]
/// - [String: AnyCodable]
/// - null (represented by `NSNull()`)
public struct AnyCodable: Codable {

    public let value: Any

    public init(_ value: Any) {
        self.value = value
    }

    // MARK: Decodable
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        // Scalar first
        if let intVal = try? container.decode(Int.self) {
            self.value = intVal
            return
        }
        if let doubleVal = try? container.decode(Double.self) {
            self.value = doubleVal
            return
        }
        if let boolVal = try? container.decode(Bool.self) {
            self.value = boolVal
            return
        }
        if let stringVal = try? container.decode(String.self) {
            self.value = stringVal
            return
        }
        if container.decodeNil() {
            self.value = NSNull()
            return
        }

        // Arrays
        if let arrayVal = try? container.decode([AnyCodable].self) {
            self.value = arrayVal
            return
        }

        // Dictionaries
        if let dictVal = try? container.decode([String: AnyCodable].self) {
            self.value = dictVal
            return
        }

        throw DecodingError.dataCorruptedError(
            in: container,
            debugDescription: "AnyCodable encountered an unsupported type"
        )
    }

    // MARK: Encodable
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()

        switch value {
        case let v as Int:
            try container.encode(v)
        case let v as Double:
            try container.encode(v)
        case let v as Bool:
            try container.encode(v)
        case let v as String:
            try container.encode(v)
        case is NSNull:
            try container.encodeNil()

        case let v as [AnyCodable]:
            try container.encode(v)
        case let v as [String: AnyCodable]:
            try container.encode(v)

        // Allow passing `[String: Any]` / `[Any]` at call sites by mapping on the fly
        case let v as [String: Any]:
            let mapped = v.mapValues { AnyCodable($0) }
            try container.encode(mapped)
        case let v as [Any]:
            let mapped = v.map { AnyCodable($0) }
            try container.encode(mapped)

        default:
            let context = EncodingError.Context(
                codingPath: encoder.codingPath,
                debugDescription: "AnyCodable cannot encode value of type \(type(of: value))"
            )
            throw EncodingError.invalidValue(value, context)
        }
    }
}

// MARK: - Convenience literal conformances (nice to have)
extension AnyCodable: ExpressibleByStringLiteral,
                      ExpressibleByBooleanLiteral,
                      ExpressibleByIntegerLiteral,
                      ExpressibleByFloatLiteral,
                      ExpressibleByArrayLiteral,
                      ExpressibleByDictionaryLiteral {

    public init(stringLiteral value: StringLiteralType) {
        self.init(value)
    }
    public init(booleanLiteral value: BooleanLiteralType) {
        self.init(value)
    }
    public init(integerLiteral value: IntegerLiteralType) {
        self.init(value)
    }
    public init(floatLiteral value: FloatLiteralType) {
        self.init(Double(value))
    }
    public init(arrayLiteral elements: AnyCodable...) {
        self.init(elements)
    }
    public init(dictionaryLiteral elements: (String, AnyCodable)...) {
        self.init(Dictionary(uniqueKeysWithValues: elements))
    }
}
