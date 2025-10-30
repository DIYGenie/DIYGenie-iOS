//
//  ProjectDetailsView.swift
//  DIYGenieApp
//

import SwiftUI

struct ProjectDetailsView: View {
    let project: Project
    @Environment(\.dismiss) private var dismiss

    @State private var isLoading = false
    @State private var showError: String?
    @State private var showDetailedPlan = false

    private let gradientTop = Color(red: 28/255, green: 26/255, blue: 40/255)
    private let gradientBottom = Color(red: 60/255, green: 35/255, blue: 126/255)
    private let accentStart = Color(red: 115/255, green: 73/255, blue: 224/255)
    private let accentEnd = Color(red: 146/255, green: 86/255, blue: 255/255)

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(colors: [gradientTop, gradientBottom],
                               startPoint: .topLeading,
                               endPoint: .bottomTrailing)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // MARK: Back Button
                        HStack {
                            Button(action: { dismiss() }) {
                                Image(systemName: "chevron.left")
                                    .foregroundColor(.white.opacity(0.9))
                                    .font(.system(size: 18, weight: .semibold))
                            }
                            Spacer()
                        }

                        // MARK: Project Info
                        Text(project.name ?? "Project Details")
                            .font(.system(size: 32, weight: .heavy))
                            .foregroundColor(.white)

                        if let goal = project.goal {
                            Text(goal)
                                .font(.system(size: 15))
                                .foregroundColor(.white.opacity(0.7))
                        }

                        // MARK: Project Image
                        AsyncImage(url: imageURL(for: project)) { phase in
                            switch phase {
                            case .success(let img):
                                img.resizable()
                                    .scaledToFit()
                                    .clipShape(RoundedRectangle(cornerRadius: 18))
                            default:
                                RoundedRectangle(cornerRadius: 18)
                                    .fill(Color.white.opacity(0.05))
                                    .overlay(
                                        Image(systemName: "photo")
                                            .foregroundColor(.white.opacity(0.3))
                                    )
                                    .frame(height: 220)
                            }
                        }

                        // MARK: Overview Section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Build Overview")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.white)

                            glassCard {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Budget: \(project.budget ?? "$$")")
                                    Text("Skill Level: \(project.skillLevel?.capitalized ?? "Intermediate")")
                                }
                                .foregroundColor(.white.opacity(0.9))
                                .font(.system(size: 15))
                            }
                        }

                        // MARK: Navigation Button
                        NavigationLink(destination: DetailedBuildPlanView(projectId: project.id,
                                                                          userId: project.userId ?? "")) {
                            Text("Open Detailed Build Plan")
                                .font(.system(size: 17, weight: .bold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 15)
                                .background(
                                    LinearGradient(colors: [accentStart, accentEnd],
                                                   startPoint: .leading,
                                                   endPoint: .trailing)
                                )
                                .foregroundColor(.white)
                                .cornerRadius(14)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 60)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Helpers
    private func imageURL(for project: Project) -> URL? {
        if let preview = project.previewURL, let url = URL(string: preview) {
            return url
        }
        if let input = project.inputImageURL, let url = URL(string: input) {
            return url
        }
        return nil
    }

    private func glassCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .padding(16)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
            .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.08), lineWidth: 1))
            .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
    }
}
