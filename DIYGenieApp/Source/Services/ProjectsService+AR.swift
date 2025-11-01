//
//  ProjectsService+AR.swift
//  DIYGenieApp
//

import Foundation
import Supabase
import RoomPlan
import QuickLook
import SwiftUI

extension ProjectsService {

    // MARK: - Upload RoomPlan .usdz → Storage + update row
    func uploadARScan(projectId: String, fileURL: URL) async throws {
        let bucket = client.storage.from("uploads")
        let path = "\(userId)/\(UUID().uuidString).usdz"
        let data = try Data(contentsOf: fileURL)

        _ = try await bucket.upload(
            path,
            data: data,
            options: .init(contentType: "model/vnd.usdz+zip")
        )

        // Build public URL (stable)
        let publicURL = SupabaseConfig.publicURL(bucket: "uploads", path: path)

        let update: [String: AnyEncodable] = ["ar_scan_url": AnyEncodable(publicURL)]
        _ = try await client
            .from("projects")
            .update(update)
            .eq("id", value: projectId)
            .execute()
    }
}

