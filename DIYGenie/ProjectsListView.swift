import SwiftUI

struct ProjectsListView: View {
    // MARK: - State
    @State private var projects: [Project] = []
    @State private var isLoading = false
    @State private var error: String?
    @State private var didLoadOnce = false

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Projects")
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            // TODO: present NewProjectView() later
                        } label: {
                            Image(systemName: "plus")
                        }
                    }
                }
                .task {
                    await loadOnce()
                }
        }
    }

    // MARK: - Content
    @ViewBuilder
    private var content: some View {
        if isLoading {
            ProgressView("Loading…")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if let error {
            VStack(spacing: 8) {
                Text("Failed to load").font(.headline)
                Text(error)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                Button("Retry") {
                    Task { await load() }
                }
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if projects.isEmpty {
            VStack(spacing: 8) {
                Text("No projects yet").font(.headline)
                Text("Create your first DIY plan from the + button.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            List(projects, id: \.id) { project in
                NavigationLink {
                    ProjectDetailView(project: project)
                } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(project.name)
                            .font(.headline)
                        if let goal = project.goal, !goal.isEmpty {
                            Text(goal)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        if let status = project.status, !status.isEmpty {
                            Text(status)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 6)
                }
            }
            .listStyle(.insetGrouped)
        }
    }

    // MARK: - Load Helpers
    private func loadOnce() async {
        guard !didLoadOnce else { return }
        didLoadOnce = true
        await load()
    }

    private func load() async {
        await MainActor.run {
            isLoading = true
            error = nil
        }

        do {
            let userId = UserSession.shared.userId
            let items = try await ProjectsService().list(userId: userId)
            await MainActor.run {
                self.projects = items
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.error = error.localizedDescription
                self.isLoading = false
            }
        }
    }
}

// ✅ Ready to Build

