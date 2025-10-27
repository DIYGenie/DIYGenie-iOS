import Foundation

struct SupabaseUploader {

    enum UploadError: Error {
        case invalidFile
        case uploadFailed
        case missingEnv
    }

    static func upload(fileURL: URL, userID: String, completion: @escaping (Result<String, Error>) -> Void) {
        guard let supabaseURL = ProcessInfo.processInfo.environment["SUPABASE_URL"],
              let supabaseKey = ProcessInfo.processInfo.environment["SUPABASE_SERVICE_KEY"] else {
            completion(.failure(UploadError.missingEnv))
            return
        }

        let fileName = fileURL.lastPathComponent
        let fileExt = fileURL.pathExtension.lowercased()
        let bucket = fileExt == "usdz" ? "roomscans" : "uploads"

        let boundary = UUID().uuidString
        let url = URL(string: "\(supabaseURL)/storage/v1/object/\(bucket)/\(userID)/\(fileName)")!

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(supabaseKey)", forHTTPHeaderField: "Authorization")
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        // Build multipart body
        var body = Data()
        body.append("--\(boundary)\r\n")
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(fileName)\"\r\n")
        body.append("Content-Type: application/octet-stream\r\n\r\n")

        do {
            let fileData = try Data(contentsOf: fileURL)
            body.append(fileData)
        } catch {
            completion(.failure(UploadError.invalidFile))
            return
        }

        body.append("\r\n--\(boundary)--\r\n")
        request.httpBody = body

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                completion(.failure(UploadError.uploadFailed))
                return
            }

            let publicURL = "\(supabaseURL)/storage/v1/object/public/\(bucket)/\(userID)/\(fileName)"
            completion(.success(publicURL))
        }
        task.resume()
    }
}

// MARK: - Helper extension
private extension Data {
    mutating func append(_ string: String) {
        if let data = string.data(using: .utf8) {
            append(data)
        }
    }
}
