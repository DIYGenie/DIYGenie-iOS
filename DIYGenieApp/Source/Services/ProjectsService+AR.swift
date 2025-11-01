//
//  ProjectsService+AR.swift
//  DIYGenieApp
//
//  Handles RoomPlan scanning, USDZ uploads, and QuickLook previews.
//

import Foundation
import Supabase
import RoomPlan
import QuickLook
import SwiftUI

extension ProjectsService {
    
    // MARK: - Upload .usdz Scan to Supabase Storage
    func uploadARScan(projectId: String, fileURL: URL) async throws -> String {
        let bucket = client.storage.from("uploads")
        let fileName = "\(userId)/\(UUID().uuidString).usdz"

        // Read file data
        let fileData = try Data(contentsOf: fileURL)
        
        // Upload to Supabase storage
        _ = try await bucket.upload(
            path: fileName,
            data: fileData,
            fileOptions: FileOptions(contentType: "model/vnd.usd+zip")
        )

        // Generate a public URL for that file
        let publicURL = bucket.getPublicUrl(path: fileName)
        print("🟢 AR file uploaded:", publicURL)

        // Update the project record in Supabase
        _ = try await client
            .from("projects")
            .update(["ar_scan_url": publicURL])
            .eq("id", value: projectId)
            .execute()
        
        return publicURL
    }
}

