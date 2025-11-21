import SwiftUI
import UIKit

struct ProjectCard: View {
    let project: Project

    // Prefer preview → input image
    private var thumbnailURL: URL? {
        if let url = project.previewURL { return url }
        if let url = project.inputImageURL { return url }
        return project.photoUrl.flatMap(URL.init(string:))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Thumbnail (Preview Image)
            if let url = thumbnailURL {
                if url.isFileURL, let image = UIImage(contentsOfFile: url.path) {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 160)
                        .clipped()
                        .cornerRadius(16)
                } else {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(height: 160)
                                .clipped()
                                .cornerRadius(16)
                        case .failure(_):
                            placeholder
                        default:
                            placeholderProgress
                        }
                    }
                }
            } else {
                placeholder
            }

            // Project Info
            VStack(alignment: .leading, spacing: 4) {
                Text(project.name)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)

                Text(project.goal ?? "No description available")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.7))
                    .lineLimit(2)
            }
            .padding(.horizontal, 4)
            .padding(.bottom, 6)
        }
        .padding()
        .background(
            LinearGradient(
                colors: [
                    Color(red: 73/255, green: 46/255, blue: 160/255),
                    Color(red: 39/255, green: 26/255, blue: 63/255)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.4), radius: 8, x: 0, y: 4)
    }

    // MARK: - Placeholders
    private var placeholder: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(Color.black.opacity(0.2))
            .frame(height: 160)
            .overlay(
                Image(systemName: "photo.on.rectangle.angled")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundColor(.white.opacity(0.7))
            )
    }

    private var placeholderProgress: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(Color.black.opacity(0.2))
            .frame(height: 160)
            .overlay(
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
            )
    }
}
