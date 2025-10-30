import SwiftUI

struct ProjectCard: View {
    let project: Project

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Thumbnail (Preview Image)
            if let thumbnail = project.previewURL,
               let url = URL(string: thumbnail) {
                AsyncImage(url: url) { image in
                    image.resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 160)
                        .cornerRadius(16)
                } placeholder: {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.black.opacity(0.2))
                        .frame(height: 160)
                        .overlay(
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        )
                }
            }

            // Project Info
            VStack(alignment: .leading, spacing: 4) {
                Text(project.name ?? "Untitled Project")
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
}
