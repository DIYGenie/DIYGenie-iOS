import Foundation

/// A simple shared user session for the app.
/// Extend this as needed (e.g., persistence, auth state, etc.).
final class UserSession {
    static let shared = UserSession()

    /// A stable identifier for the current user. Replace with real auth when available.
    let userId: String

    private init() {
        // Use a stable, real profile UUID for iOS debug builds.
        // This must exist in profiles.id on the server.
        self.userId = "e4cb3591-7272-46dd-b1f6-d7cc4e2f3d24"
    }
}
