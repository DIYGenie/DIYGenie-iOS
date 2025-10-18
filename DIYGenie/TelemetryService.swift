import Foundation

struct TelemetryService {
    private let api = APIClient.shared

    struct EventBody: Encodable {
        let name: String
        let metadata: [String: String]?
    }

    @discardableResult
    func log(event name: String, metadata: [String: String]? = nil) async throws -> BoolResponse {
        let body = EventBody(name: name, metadata: metadata)
        return try await api.post("/api/events", body: body)
    }
}
