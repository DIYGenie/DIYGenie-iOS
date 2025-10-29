import SwiftUI

struct ProjectsListView: View {
    @State private var projects: [Project] = []
    @State private var isLoading = false
    @State private var alertMessage = ""

    private let projectsService = ProjectsService.shared

    var body: some View {
        NavigationView {
            List {
                if isLoading {
                    ProgressView("Loading projects…")
                } else {
                    ForEach(projects) { project in
                        NavigationLink(destination: ProjectDetailsView(project: project)) {
                            VStack(alignment: .leading) {
                                Text(project.name)
                                    .font(.headline)
                                Text(project.goal)
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                }
            }
            .navigationTitle("My Projects")
            .task {
                await loadProjects()
            }
        }
    }

    private func loadProjects() async {
        do {
            isLoading = true
            projects = try await projectsService.fetchProjects(for: "USER_ID_HERE")
        } catch {
            alertMessage = error.localizedDescription
        }
        isLoading = false
    }
}
