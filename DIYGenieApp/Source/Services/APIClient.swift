// DIYGenieApp/Source/Services/APIClient.swift
//
//  APIClient.swift
//  DIYGenieApp
//
//  API client for backend communication.
//

import Foundation
import OSLog

// MARK: - API Client

final class APIClient {
    static let shared = APIClient()
    
    private let baseURL: URL
    private let logger: Logger
    private let urlSession: URLSession
    
    private init() {
        self.baseURL = URL(string: "https://api.diygenieapp.com")!
        self.logger = Logger(subsystem: "com.diygenieapp.ios", category: "api")
        
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 60.0      // per-request timeout
        config.timeoutIntervalForResource = 90.0     // overall resource timeout
        self.urlSession = URLSession(configuration: config)
    }
    
    // MARK: - Generate Plan
    
    func generatePlan(projectId: UUID) async throws -> PlanV1 {
        let url = baseURL.appendingPathComponent("api/projects/\(projectId.uuidString)/generate-plan")
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        // Optional: Add Authorization header if token is available
        if let token = getAuthToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        logger.info("Generating plan for project \(projectId.uuidString)")
        
        do {
            let (data, response) = try await urlSession.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }
            
            guard (200..<300).contains(httpResponse.statusCode) else {
                let bodyString = String(data: data, encoding: .utf8) ?? "<no body>"
                logger.error("Plan generation failed: status \(httpResponse.statusCode), body: \(bodyString)")
                throw APIError.serverError(statusCode: httpResponse.statusCode, body: bodyString)
            }
            
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            
            do {
                let plan = try decoder.decode(PlanV1.self, from: data)
                logger.info("Plan generated successfully: \(plan.id.uuidString)")
                return plan
            } catch {
                let bodyString = String(data: data, encoding: .utf8) ?? "<no body>"
                logger.error("Failed to decode plan response: \(error.localizedDescription), body: \(bodyString)")
                throw APIError.decodeError(error)
            }
        } catch let error as APIError {
            throw error
        } catch {
            logger.error("Network error during plan generation: \(error.localizedDescription)")
            throw APIError.networkError(error)
        }
    }
    
    // MARK: - Helpers
    
    private func getAuthToken() -> String? {
        // Check UserDefaults or keychain for auth token
        // For now, return nil - can be extended later
        return nil
    }
}

// MARK: - API Errors

enum APIError: LocalizedError {
    case invalidResponse
    case serverError(statusCode: Int, body: String)
    case decodeError(Error)
    case networkError(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid server response"
        case .serverError(let statusCode, let body):
            return "Server error (\(statusCode)): \(body)"
        case .decodeError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
}
