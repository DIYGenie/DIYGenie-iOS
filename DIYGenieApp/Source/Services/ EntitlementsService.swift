import Foundation

/// Service responsible for loading entitlements from the DIY Genie backend.
final class EntitlementsService {

    static let shared = EntitlementsService()

    private init() {}

    // If you already have a global API base URL somewhere, you can replace this.
    private let baseURL = URL(string: "https://api.diygenieapp.com")!

    /// Fetch entitlements for a given Supabase user id.
    func fetchEntitlements(
        userId: String,
        completion: @escaping (Result<Entitlements, Error>) -> Void
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
                let decoded = try JSONDecoder().decode(Entitlements.self, from: data)
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
