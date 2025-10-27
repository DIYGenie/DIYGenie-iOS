// SupabaseUploader.swift
// DIYGenieApp
//
// Handles file uploads to Supabase storage (rooms-scans or uploads bucket)

import Foundation
import Supabase

struct SupabaseUploader {
    static let client = SupabaseClient(
        supabaseURL: URL(string: "https://qnevigmqyuxfzyczmctc.supabase.co")!,
        supabaseKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFuZXZpZ21xeXV4Znp5Y3ptY3RjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTg5NDc5MjUsImV4cCI6MjA3NDUyMzkyNX0.5wKtzwtNDZt6jjE5gYqNqqWATTdd7g2zVdHB231Z1wQ"    )

    static func uploadRoomScan(localURL: URL, projectId: String, completion: @escaping (Result<String, Error>) -> Void) {
        Task {
            do {
                let fileName = localURL.lastPathComponent
                let fileData = try Data(contentsOf: localURL)

                // Upload to the "room-scans" bucket
                let path = "room-scans/\(projectId)/\(fileName)"
                try await client.storage.from("room-scans").upload(path, data: fileData)

                // Get public URL
                let publicURL = try client.storage.from("room-scans").getPublicURL(path: path)

                // Optionally update your projects table with the scan URL
                try await client
                    .from("projects")
                    .update(["scan_url": publicURL.absoluteString])
                    .eq("id", value: projectId)
                    .execute()

                completion(.success(publicURL.absoluteString))
            } catch {
                completion(.failure(error))
            }
        }
    }
}
