//
//  ProjectsService+AR.swift
//  DIYGenieApp
//
//  RoomPlan / AR scan upload (.usdz) → Storage → update row
//

import Foundation
import Supabase
import RoomPlan
import QuickLook
import SwiftUI

extension ProjectsService {

    // MARK: Upload RoomPlan .usdz → Supabase Storage → update row
    func uploadARScan(projectId: String, fileURL: URL) async throws {
        let bucket = client.storage.from("uploads")
        let path = "\(userId)/\(UUID().uuidString).usdz"
        let data = try Data(contentsOf: fileURL)

        // Supabase v2.36.0 signature: upload(_ path: String, data: Data, options: FileOptions?)
        _ = try await bucket.upload(
            path,
            data: data,
            options: .init(contentType: "model/vnd.usdz+zip")
        )

        // Build a stable public URL (SDK no longer provides getPublicUrl)
        let publicURL = SupabaseConfig.publicURL(bucket: "uploads", path: path)

        // Update project row
        let update: [String: AnyEncodable] = ["ar_scan_url": AnyEncodable(publicURL)]
        _ = try await client
            .from("projects")
            .update(update)
            .eq("id", value: projectId)
            .execute()
    }

    // MARK: QuickLook helper for USDZ preview (retains data source strongly)
    static func quickLookPreview(for usdzURL: URL) -> QLPreviewController {
        final class DataSource: NSObject, QLPreviewControllerDataSource {
            let url: URL
            init(_ url: URL) { self.url = url }
            func numberOfPreviewItems(in controller: QLPreviewController) -> Int { 1 }
            func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
                url as NSURL
            }
        }

        final class RetainingQLController: QLPreviewController {
            var strongDataSource: DataSource?
        }

        let controller = RetainingQLController()
        let ds = DataSource(usdzURL)
        controller.strongDataSource = ds
        controller.dataSource = ds
        return controller
    }
}

