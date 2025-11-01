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
    
    // MARK: - Upload USDZ file to Supabase Storage
    func uploadUSDZ(for projectId: String, fileURL: URL) async throws -> String {
        let bucket = client.storage.from("uploads")
        let fileData = try Data(contentsOf: fileURL)
        let fileName = "\(userId)/\(UUID().uuidString).usdz"
        
        // Upload using the new Supabase syntax
        _ = try await bucket.upload(path: fileName, file: fileData, options: FileOptions(contentType: "model/vnd.usdz+zip"))
        
        let publicURL = try bucket.getPublicUrl(fileName)
        let urlString = publicURL.absoluteString
        
        // Update project in Supabase
        _ = try await client
            .from("projects")
            .update([
                "reference_object": AnyEncodable(urlString),
                "ar_provider": AnyEncodable("roomplan"),
                "ar_confidence": AnyEncodable(1.0)
            ])
            .eq("id", value: projectId)
            .execute()
        
        print("🟢 Uploaded USDZ file and linked to project:", urlString)
        return urlString
    }
    
    
    // MARK: - Preview USDZ with QuickLook
    func previewUSDZ(_ urlString: String, on viewController: UIViewController) {
        guard let url = URL(string: urlString) else {
            print("🔴 Invalid USDZ URL:", urlString)
            return
        }
        
        let previewController = QLPreviewController()
        previewController.dataSource = QuickLookPreviewSource(url: url)
        viewController.present(previewController, animated: true)
    }
}


// MARK: - QuickLook Helper
final class QuickLookPreviewSource: NSObject, QLPreviewControllerDataSource {
    private let url: URL
    
    init(url: URL) {
        self.url = url
    }
    
    func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
        return 1
    }
    
    func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
        return url as QLPreviewItem
    }
}

