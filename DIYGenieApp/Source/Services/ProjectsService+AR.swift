//
//  ProjectsService+AR.swift
//  DIYGenieApp
//
//  Upload RoomPlan .usdz → Supabase Storage → update scan_json + ar_provider
//

import Foundation
import Supabase

extension ProjectsService {

    /// Uploads a RoomPlan .usdz, then writes:
    /// - scan_json = { usdz_url, provider, saved_at }
    /// - ar_provider = 'roomplan'
    func uploadARScan(projectId: String, fileURL: URL) async throws {
        let data = try Data(contentsOf: fileURL)
        let path = "\(userId)/\(UUID().uuidString).usdz"

        // 1) Upload to Storage
        _ = try await client.storage
            .from("uploads")
            .upload(
                path: path,
                file: data,
                options: FileOptions(contentType: "model/vnd.usdz+zip")
            )

        // 2) Build public URL
        let publicURLString = SupabaseConfig.publicURL(bucket: "uploads", path: path).absoluteString

        // 3) Update row
        let nowISO = ISO8601DateFormatter().string(from: Date())
        let scanPayload: [String: AnyEncodable] = [
            "usdz_url": AnyEncodable(publicURLString),
            "provider": AnyEncodable("roomplan"),
            "saved_at": AnyEncodable(nowISO)
        ]

        let update: [String: AnyEncodable] = [
            "scan_json": AnyEncodable(scanPayload),
            "ar_provider": AnyEncodable("roomplan")
        ]

        _ = try await client
            .from("projects")
            .update(update)
            .eq("id", value: projectId)
            .execute()
    }

    /// Backwards-compat alias to match earlier callsites.
    func attachARScan(projectId: String, fileURL: URL) async throws {
        try await uploadARScan(projectId: projectId, fileURL: fileURL)
    }
}

