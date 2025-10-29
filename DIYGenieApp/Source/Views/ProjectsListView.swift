//
//  ProjectsListView.swift
//  DIYGenieApp
//

import SwiftUI

struct ProjectsListView: View {
    @State private var projects: [Project] = []
    @State private var isLoading = false
    @State private var alertMessage: String?
    
    // Replace this with your logged-in user ID from Supabase auth or state
    private let projectsService = ProjectsService(userId: "demo-user")

    var body: some View {
        NavigationView {
            Group {
                if isLoading {
                    VStack {
                        ProgressView("Loading projects…")
                            .progressViewStyle(CircularProgressViewStyle(tint: .accentColor))
                            .padding()
                        Text("Fetching your DIY projects")
                            .foregroundColor(.secondary)
                    }
                } else if projects.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "hammer")
                            .font(.system(size: 48))
                            .foregroundColor(.accentColor)
                        Text("No projects yet")
                            .font(.headline)
                        Text("Start your first project to see it here.")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    .padding()
                } else {
                    List(projects) { project in
                        NavigationLink(destination: ProjectDetailsView(project: project)) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(project.name ?? "Untitled Project")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                if let goal = project.goal, !goal.isEmpty {
                                    Text(goal)
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle("My Projects")
            .task { await loadProjects() }
            .alert("Error", isPresented: .constant(alertMessage != nil)) {
                Button("OK") { alertMessage = nil }
            } message: {
                Text(alertMessage ?? "")
            }
        }
    }

    // MARK: - Data loading
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
