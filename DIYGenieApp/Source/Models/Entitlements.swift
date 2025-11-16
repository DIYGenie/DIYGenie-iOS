import Foundation

/// Entitlement information returned by the backend for the current user.
struct Entitlements: Decodable, Equatable {
    let ok: Bool
    let tier: String
    let quota: Int
    let remaining: Int
    let previewAllowed: Bool

    enum CodingKeys: String, CodingKey {
        case ok
        case tier
        case quota
        case remaining
        case previewAllowed
    }

    /// Safe default for guests / failures.
    static let `default` = Entitlements(
        ok: true,
        tier: "Free",
        quota: 2,
        remaining: 2,
        previewAllowed: false
    )
}
