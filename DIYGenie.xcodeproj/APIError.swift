import Foundation

enum APIError: Error {
    case invalidURL
    case invalidResponse
    case decodingError
    case networkFailure

    var localizedDescription: String {
        switch self {
        case .invalidURL:
            return "The URL provided was invalid."
        case .invalidResponse:
            return "The response from the server was invalid."
        case .decodingError:
            return "Failed to decode the data."
        case .networkFailure:
            return "Network request failed."
        }
    }
}
