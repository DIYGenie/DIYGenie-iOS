import Foundation
import Supabase
import UIKit

struct SupabaseUploader {
    private let client: SupabaseClient

    init() {
        guard
            let supabaseUrlString = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_URL") as? String,
            let supabaseKey = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_ANON_KEY") as? String,
            let supabaseUrl = URL(string: supabaseUrlString)
        else {
            fatalError("❌ Missing Supabase credentials in Info.plist")
        }

        client = SupabaseClient(supabaseURL: supabaseUrl, supabaseKey: supabaseKey)
    }

    /// Uploads a UIImage to Supabase Storage and returns the public URL
    func uploadImage(_ image: UIImage, toFolder folder: String) async throws -> String {
        // ✅ Corrected error case — must be .cannotEncodeContentData
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw URLError(.cannotEncodeContentData)
        }

        let fileName = "photo-\(UUID().uuidString).jpg"
        let filePath = "\(folder)/\(fileName)"

        // ✅ Remove the deprecated contentType param; Supabase infers it automatically
        _ = try await client.storage
            .from("uploads")
            .upload(path: filePath, file: imageData)

        // ✅ Return the public URL (throws)
        let publicURL = try client.storage
            .from("uploads")
            .getPublicURL(path: filePath)
            .absoluteString

        return publicURL
    }
}
