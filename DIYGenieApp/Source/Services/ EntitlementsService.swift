import Foundation

// MARK: - Entitlements model

/// Entitlements returned by the DIY Genie backend.
struct BackendEntitlements: Decodable {
    let tier: String
    let quota: Int
    let remaining: Int
    let previewAllowed: Bool

    /// Safe default value used when the backend is unavailable or decoding fails.
    static let `default` = BackendEntitlements(
        tier: "Free",
        quota: 2,
        remaining: 2,
        previewAllowed: false
    )
}

// MARK: - Entitlements service

/// Service responsible for loading entitlements from the DIY Genie backend.
final class EntitlementsService {

    static let shared = EntitlementsService()

    private init() {}

    // If you already have a global API base URL somewhere, you can replace this.
    private let baseURL = URL(string: "https://api.diygenieapp.com")!

    /// Fetch entitlements for a given Supabase user id.
    func fetchEntitlements(
        userId: String,
        completion: @escaping (Result<BackendEntitlements, Error>) -> Void
    ) {
        let url = baseURL.appendingPathComponent("api/me/entitlements/\(userId)")

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 15

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
                return
            }

            guard let data = data else {
                DispatchQueue.main.async {
                    completion(.success(.default))
                }
                return
            }

            do {
                let decoded = try JSONDecoder().decode(BackendEntitlements.self, from: data)
                DispatchQueue.main.async {
                    completion(.success(decoded))
                }
            } catch {
                // On decode failure, fall back to Free defaults.
                DispatchQueue.main.async {
                    completion(.success(.default))
                }
            }
        }.resume()
    }
}
