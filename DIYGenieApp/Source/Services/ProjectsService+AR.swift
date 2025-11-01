//
//  ProjectsService+AR.swift
//  DIYGenieApp
//

import Foundation
import Supabase

extension ProjectsService {

    // MARK: - Upload AR Scan (.usdz)
    func uploadARScan(projectId: String, fileURL: URL) async throws {
        let bucket = client.storage.from("uploads")
        let filename = "\(userId)/\(UUID().uuidString).usdz"
        let fileData = try Data(contentsOf: fileURL)

        // ✅ New Supabase v2.5+ syntax
        _ = try await bucket.upload(filename, data: fileData, options: ["contentType": "model/vnd.usdz+zip"])

        // ✅ Public URL
        let publicURL = bucket.getPublicUrl(path: filename).publicUrl

        // ✅ Save to projects table
        _ = try await client
            .from("projects")
            .update(["ar_scan_url": AnyEncodable(publicURL)])
            .eq("id", value: projectId)
            .execute()

        print("🟢 AR scan uploaded: \(publicURL)")
    }

    // MARK: - Delete AR Scan
    func deleteARScan(projectId: String) async throws {
        let bucket = client.storage.from("uploads")

        let response = try await client
            .from("projects")
            .select("ar_scan_url")
            .eq("id", value: projectId)
            .single()
            .execute()

        guard
            let data = response.data,
            let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let urlString = json["ar_scan_url"] as? String,
            let url = URL(string: urlString)
        else {
            print("⚠️ No AR scan URL found for project \(projectId)")
            return
        }

        let path = url.path.replacingOccurrences(of: "/storage/v1/object/public/uploads/", with: "")
        _ = try await bucket.remove(paths: [path])

        print("🗑️ AR scan removed for project \(projectId)")
    }
}

