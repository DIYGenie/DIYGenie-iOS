// ProjectsListView.swift
import SwiftUI

struct ProjectsListView: View {
    @State private var projects: [Project] = []
    @State private var isLoading: Bool = false
    @State private var showAlert = false
    @State private var alertMessage = ""

    // Use your actual UUID here as we did in NewProjectView.
    private let projectsService = ProjectsService(userId: "99198c4b-8470-49e2-895c-75593c5aa181")

    var body: some View {
        NavigationView {
            List {
                if isLoading {
                    ProgressView("Loading projects…")
                        .frame(maxWidth: .infinity, alignment: .center)
                } else {
                    ForEach(projects, id: \.id) { project in
                        NavigationLink(destination: ProjectDetailsView(project: project)) {
                            HStack(spacing: 12) {
                                // Show preview image if available, else original image if available.
                                if let url = project.previewURL ?? project.inputImageURL {
                                    AsyncImage(url: url) { image in
                                        image
                                            .resizable()
                                            .scaledToFill()
                                    } placeholder: {
                                        Rectangle()
                                            .fill(Color.gray.opacity(0.2))
                                    }
                                    .frame(width: 60, height: 60)
                                    .clipped()
                                    .cornerRadius(8)
                                } else {
                                    Rectangle()
                                        .fill(Color.gray.opacity(0.1))
                                        .frame(width: 60, height: 60)
                                        .cornerRadius(8)
                                }
                                VStack(alignment: .leading) {
                                    Text(project.name)
                                        .font(.headline)
                                    Text(project.status.capitalized)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
            .navigationTitle("Projects")
            .onAppear {
                Task { await loadProjects() }
            }
            .alert(isPresented: $showAlert) {
                Alert(title: Text("Error"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
            }
        }
    }

    /// Load all projects for the current user.
    @MainActor
    private func loadProjects() async {
        isLoading = true
        do {
            let list = try await projectsService.fetchProjects()
            projects = list
        } catch {
            alertMessage = error.localizedDescription
            showAlert = true
        }
        isLoading = false
    }
}
