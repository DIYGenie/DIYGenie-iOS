import Foundation

enum APIError: Error {
    case http(Int, String)
    case decoding(String)
    case network(String)
    case unknown

    var localizedDescription: String {
        switch self {
        case let .http(status, body):
            return "HTTP \(status): \(body)"
        case let .decoding(message):
            return "Decoding error: \(message)"
        case let .network(message):
            return "Network error: \(message)"
        case .unknown:
            return "Unknown error"
        }
    }
}
