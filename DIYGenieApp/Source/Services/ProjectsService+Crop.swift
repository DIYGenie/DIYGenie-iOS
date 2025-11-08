//
//  ProjectsService+Crop.swift
//  DIYGenieApp
//

import Foundation
import Supabase

extension ProjectsService {
    /// Stores a normalized crop rect (0..1) into `projects.crop_rect` if that column exists.
    /// This is a best-effort helper; failures are ignored so it won’t block the flow.
    func attachCropRectIfAvailable(projectId: String, rect: CGRect) async {
        let payload: [String: AnyEncodable] = [
            "crop_rect": AnyEncodable([
                "x": rect.origin.x,
                "y": rect.origin.y,
                "w": rect.size.width,
                "h": rect.size.height
            ])
        ]
        do {
            _ = try await client
                .from("projects")
                .update(payload)
                .eq("id", value: projectId)
                .execute()
        } catch {
            // intentionally ignore (column may not exist in your current schema)
            print("attachCropRectIfAvailable skipped: \(error.localizedDescription)")
        }
    }
}

