import Foundation

/// A simple shared user session for the app.
/// Extend this as needed (e.g., persistence, auth state, etc.).
final class UserSession {
    static let shared = UserSession()

    /// A stable identifier for the current user. Replace with real auth when available.
    let userId: String

    private init() {
        // For now, generate or return a placeholder user ID.
        // In a real app, this might come from Keychain, sign-in, or server.
        if let existing = UserDefaults.standard.string(forKey: "UserSession.userId") {
            self.userId = existing
        } else {
            let new = UUID().uuidString
            UserDefaults.standard.set(new, forKey: "UserSession.userId")
            self.userId = new
        }
    }
}
