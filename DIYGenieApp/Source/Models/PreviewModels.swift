import Foundation

/// Request body for starting a Decor8 preview for a project.
struct PreviewRequestBody: Encodable {
    let projectId: String   // Supabase UUID string
}

/// Response when triggering a preview.
///
/// Backend shape:
/// { "ok": true, "preview_url": "https://..." }  OR  { "ok": false, "error": "..." }
struct PreviewTriggerResponse: Decodable {
    let ok: Bool
    let previewURL: URL?
    let error: String?

    enum CodingKeys: String, CodingKey {
        case ok
        case previewURL = "preview_url"
        case error
    }
}

/// Response when asking for existing preview status.
///
/// Backend shape:
/// { "ok": true, "preview_status": "ready|pending|error", "preview_url": "https://..." }
struct PreviewStatusResponse: Decodable {
    let ok: Bool
    let previewStatus: String?
    let previewURL: URL?
    let error: String?

    enum CodingKeys: String, CodingKey {
        case ok
        case previewStatus = "preview_status"
        case previewURL = "preview_url"
        case error
    }
}
