import SwiftUI

/// The main home screen for DIY Genie — welcoming the user and showcasing project templates.
struct HomeView: View {
    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {

                    // MARK: - Greeting
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Welcome back, Tye")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(Color.primary)

                        Text("Ready to start your next DIY project?")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)

                    // MARK: - Hero Image Card
                    VStack(alignment: .leading, spacing: 0) {
                        ZStack(alignment: .bottomLeading) {
                            Image("forest")
                                .resizable()
                                .scaledToFill()
                                .frame(height: 200)
                                .clipped()
                                .cornerRadius(16)
                            
                            LinearGradient(
                                gradient: Gradient(colors: [Color.black.opacity(0.4), Color.clear]),
                                startPoint: .bottom,
                                endPoint: .center
                            )
                            .cornerRadius(16)

                            Text("See your space transform")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding()
                        }

                        // Step Indicator
                        HStack(spacing: 6) {
                            Circle().fill(Color.purple).frame(width: 8, height: 8)
                            Circle().fill(Color.gray.opacity(0.4)).frame(width: 8, height: 8)
                            Circle().fill(Color.gray.opacity(0.4)).frame(width: 8, height: 8)
                            Circle().fill(Color.gray.opacity(0.4)).frame(width: 8, height: 8)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 8)

                        Text("1 Describe • 2 Scan • 3 Preview • 4 Build")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity)
                            .padding(.top, 4)
                    }
                    .padding(.horizontal)

                    // MARK: - Template Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Start with a template")
                            .font(.headline)
                            .foregroundColor(.purple)
                            .padding(.horizontal)

                        VStack(spacing: 12) {
                            TemplateRow(title: "Shelf", subtitle: "Clean, modern storage")
                            TemplateRow(title: "Accent Wall", subtitle: "Add depth and contrast")
                            TemplateRow(title: "Mudroom Bench", subtitle: "Entryway organization")
                        }
                        .padding(.horizontal)
                    }

                    Spacer()
                }
                .padding(.top, 24)
            }
            .navigationTitle("Home")
            .navigationBarTitleDisplayMode(.inline)
            .background(Color(.systemBackground))
        }
    }
}

// MARK: - Template Row Component
struct TemplateRow: View {
    var title: String
    var subtitle: String

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Text("Create")
                .font(.headline)
                .foregroundColor(.purple)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(14)
    }
}

#Preview {
    HomeView()
}
