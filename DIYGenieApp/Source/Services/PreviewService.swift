import Foundation

// MARK: - Preview service

/// Service responsible for talking to the Decor8 preview endpoints on the backend.
final class PreviewService {

    static let shared = PreviewService()

    private init() {}

    private let baseURL = URL(string: "https://api.diygenieapp.com")!

    // MARK: - Trigger Preview

    func requestPreview(
        for projectId: String,
        completion: @escaping (Result<PreviewTriggerResponse, Error>) -> Void
    ) {
        let url = baseURL.appendingPathComponent("preview/decor8")

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = PreviewRequestBody(projectId: projectId)

        do {
            request.httpBody = try JSONEncoder().encode(body)
        } catch {
            completion(.failure(error))
            return
        }

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                DispatchQueue.main.async { completion(.failure(error)) }
                return
            }

            guard let data = data else {
                DispatchQueue.main.async {
                    completion(.failure(NSError(
                        domain: "PreviewService",
                        code: -1,
                        userInfo: [NSLocalizedDescriptionKey: "Empty response"]
                    )))
                }
                return
            }

            do {
                let decoded = try JSONDecoder().decode(PreviewTriggerResponse.self, from: data)
                DispatchQueue.main.async { completion(.success(decoded)) }
            } catch {
                DispatchQueue.main.async { completion(.failure(error)) }
            }
        }.resume()
    }

    // MARK: - Fetch Existing Status

    func fetchPreviewStatus(
        for projectId: String,
        completion: @escaping (Result<PreviewStatusResponse, Error>) -> Void
    ) {
        let url = baseURL.appendingPathComponent("preview/status/\(projectId)")

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 15

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                DispatchQueue.main.async { completion(.failure(error)) }
                return
            }

            guard let data = data else {
                DispatchQueue.main.async {
                    completion(.failure(NSError(
                        domain: "PreviewService",
                        code: -1,
                        userInfo: [NSLocalizedDescriptionKey: "Empty response"]
                    )))
                }
                return
            }

            do {
                let decoded = try JSONDecoder().decode(PreviewStatusResponse.self, from: data)
                DispatchQueue.main.async { completion(.success(decoded)) }
            } catch {
                DispatchQueue.main.async { completion(.failure(error)) }
            }
        }.resume()
    }
}
