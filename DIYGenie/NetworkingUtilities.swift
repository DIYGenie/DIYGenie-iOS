import Foundation

// Central API error type used by APIClient and services
enum APIError: Error, LocalizedError {
    case unknown(message: String?)
    case statusCode(Int)
    case decoding(underlying: String)
    case httpError(status: Int, responseBody: String)
    case invalidRequest(String)

    var errorDescription: String? {
        switch self {
        case .unknown(let message):
            return message ?? "An unknown error occurred."
        case .statusCode(let code):
            return "Request failed with status code \(code)."
        case .decoding(let underlying):
            return "Failed to decode server response: \(underlying)"
        case .httpError(let status, let body):
            return "HTTP \(status): \(body)"
        case .invalidRequest(let reason):
            return reason
        }
    }
}

// Common JSONDecoder with ISO8601 date support
extension JSONDecoder {
    static var iso8601Decoder: JSONDecoder {
        let decoder = JSONDecoder()
        let formatter = ISO8601DateFormatter()
        // Include fractional seconds if present
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let string = try container.decode(String.self)
            if let date = formatter.date(from: string) {
                return date
            }
            // Try without fractional seconds as a fallback
            let fallback = ISO8601DateFormatter()
            fallback.formatOptions = [.withInternetDateTime]
            if let date = fallback.date(from: string) {
                return date
            }
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid ISO8601 date: \(string)")
        }
        return decoder
    }
}
