import Foundation

public enum APIError: Error, LocalizedError {
    case invalidRequest(String)
    case network(underlying: String)
    case httpError(status: Int, responseBody: String)
    case decoding(underlying: String)

    public var errorDescription: String? {
        switch self {
        case .invalidRequest(let msg):            return msg
        case .network(let u):                     return "Network error: \(u)"
        case .httpError(let s, let body):         return "HTTP \(s): \(body)"
        case .decoding(let u):                    return "Decoding failed: \(u)"
        }
    }
}
