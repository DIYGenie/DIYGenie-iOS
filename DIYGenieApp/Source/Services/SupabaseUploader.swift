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

    func uploadImage(_ image: UIImage, toFolder folder: String) async throws -> String {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw URLError(.dataNotAllowed)
        }

        let fileName = "photo-\(UUID().uuidString).jpg"
        let filePath = "\(folder)/\(fileName)"

        // ✅ Correct Supabase v2.5.1 upload
        _ = try await client.storage
            .from("uploads")
            .upload(filePath, data: imageData)

        // ✅ Get public URL
        let publicURL = try client.storage
            .from("uploads")
            .getPublicURL(path: filePath)
            .absoluteString

        return publicURL
    }
}
