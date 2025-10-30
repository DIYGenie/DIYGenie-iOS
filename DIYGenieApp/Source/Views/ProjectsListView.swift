//
//  ProjectsListView.swift
//  DIYGenieApp
//

import SwiftUI

struct ProjectsListView: View {
    @State private var projects: [Project] = []
    @State private var isLoading = false
    @State private var alertMessage: String?
    @State private var userId: String = "demo-user" // Replace with real Supabase userId later
    
    private let projectsService = ProjectsService(userId: "demo-user")

    private let gradientTop = Color(red: 28/255, green: 26/255, blue: 40/255)
    private let gradientBottom = Color(red: 58/255, green: 35/255, blue: 110/255)
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
                    VStack {
                        ProgressView("Loading your DIY projects…")
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .padding(.bottom, 8)
                        Text("Fetching from your workspace")
                            .foregroundColor(.white.opacity(0.6))
                            .font(.subheadline)
                    }
                } else if projects.isEmpty {
                    VStack(spacing: 14) {
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
                                NavigationLink(
                                    destination: ProjectDetailsView(project: project, userId: userId)
                                ) {
                                    ProjectCard(project: project)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                    }
                }
            }
            .navigationTitle("Your Projects")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(Color.black.opacity(0.1), for: .navigationBar)
            .preferredColorScheme(.dark)
            .task { await loadProjects() }
            .alert("Error", isPresented: Binding(
                get: { alertMessage != nil },
                set: { _ in alertMessage = nil }
            )) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(alertMessage ?? "")
            }
        }
    }

    // MARK: - Networking
    private func loadProjects() async {
        isLoading = true
        do {
            projects = try await projectsService.fetchProjects()
        } catch {
            alertMessage = error.localizedDescription
        }
        isLoading = false
    }
}

struct ProjectCard: View {
    let project: Project

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let previewURL = project.previewURL,
               let url = URL(string: previewURL) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        Color.white.opacity(0.05)
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(height: 160)
                            .clipped()
                    case .failure:
                        Color.black.opacity(0.1)
                    @unknown default:
                        EmptyView()
                    }
                }
                .cornerRadius(16)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(project.name ?? "Untitled Project")
                    .font(.headline)
                    .foregroundColor(.white)
                if let goal = project.goal {
                    Text(goal)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.6))
                        .lineLimit(2)
                }
                Text("Skill: \(project.skillLevel ?? "Unknown") | Budget: \(project.budget ?? "$$")")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.5))
            }
            .padding(12)
        }
        .background(Color.white.opacity(0.05))
        .cornerRadius(18)
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.25), radius: 6, x: 0, y: 3)
    }
}
