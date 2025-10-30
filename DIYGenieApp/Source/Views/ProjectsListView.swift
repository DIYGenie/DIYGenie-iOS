//
//  ProjectsListView.swift
//  DIYGenieApp
//

import SwiftUI

struct ProjectsListView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var projects: [Project] = []
    @State private var isLoading = false
    @State private var errorText: String?

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

                if isLoading {
                    ProgressView("Loading Projects…")
                        .tint(.white)
                        .foregroundColor(.white)
                } else if let error = errorText {
                    VStack(spacing: 12) {
                        Text("Error loading projects")
                            .foregroundColor(.white)
                        Text(error)
                            .foregroundColor(.white.opacity(0.7))
                            .font(.caption)
                        Button("Retry") {
                            Task { await loadProjects() }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(accentStart)
                    }
                } else if projects.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "hammer.fill")
                            .font(.system(size: 48))
                            .foregroundColor(.white.opacity(0.4))
                        Text("No Projects Yet")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                        Text("Create a new project to get started.")
                            .font(.system(size: 15))
                            .foregroundColor(.white.opacity(0.7))
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 18) {
                            ForEach(projects) { project in
                                NavigationLink {
                                    ProjectDetailsView(project: project)
                                } label: {
                                    ProjectCard(project: project)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                        .padding(.bottom, 40)
                    }
                }
            }
            .navigationTitle("Your Projects")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white.opacity(0.9))
                    }
                }
            }
        }
        .task { await loadProjects() }
        .preferredColorScheme(.dark)
    }

    // MARK: - Networking
    private func loadProjects() async {
        isLoading = true
        errorText = nil
        defer { isLoading = false }
        guard let userId = UserDefaults.standard.string(forKey: "user_id") else {
            errorText = "Missing user ID"
            return
        }
        let service = ProjectsService(userId: userId)
        do {
            projects = try await service.fetchProjects()
        } catch {
            errorText = error.localizedDescription
        }
    }
}

// MARK: - Card UI
private struct ProjectCard: View {
    let project: Project
    private let accentStart = Color(red: 115/255, green: 73/255, blue: 224/255)
    private let accentEnd = Color(red: 146/255, green: 86/255, blue: 255/255)

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            AsyncImage(url: imageURL) { phase in
                switch phase {
                case .success(let img):
                    img.resizable()
                        .scaledToFill()
                        .frame(height: 180)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                default:
                    ZStack {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.white.opacity(0.05))
                        Image(systemName: "photo")
                            .foregroundColor(.white.opacity(0.4))
                            .font(.system(size: 28))
                    }
                    .frame(height: 180)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(project.name ?? "Untitled Project")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)

                if let goal = project.goal, !goal.isEmpty {
                    Text(goal)
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.75))
                        .lineLimit(2)
                }
            }
            .padding(12)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18))
            .overlay(RoundedRectangle(cornerRadius: 18)
                .stroke(Color.white.opacity(0.08), lineWidth: 1))
        }
        .shadow(color: .black.opacity(0.25), radius: 10, x: 0, y: 6)
    }

    private var imageURL: URL? {
        if let preview = project.previewURL, let url = URL(string: preview) {
            return url
        }
        if let input = project.inputImageURL, let url = URL(string: input) {
            return url
        }
        return nil
    }
}
