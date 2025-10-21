import SwiftUI

struct ProjectsListView: View {
    @State private var projects: [Project] = []
    @State private var isLoading = false
    @State private var didLoadOnce = false
    @State private var error: String?
    @State private var showCreate = false

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Projects")
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button { showCreate = true } label: {
                            Image(systemName: "plus")
                        }
                    }
                }
                .sheet(isPresented: $showCreate) {
                    NewProjectView { new in
                        projects.insert(new, at: 0)
                    }
                }
                .task { await loadOnce() }
        }
    }

    // MARK: - Content
    @ViewBuilder
    private var content: some View {
        if isLoading {
            ProgressView("Loading…")
        } else if let error {
            VStack(spacing: 8) {
                Text("Failed to load").font(.headline)
                Text(error)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                Button("Retry") { Task { await reload() } }
            }
            .padding()
        } else if projects.isEmpty {
            VStack(spacing: 8) {
                Text("No projects yet").font(.headline)
                Text("Tap + to create your first project.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .padding()
        } else {
            List(projects, id: \.id) { p in
                NavigationLink {
                    ProjectDetailView(project: p)
                } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(p.name).font(.headline)
                        if let goal = p.goal, !goal.isEmpty {
                            Text(goal).font(.subheadline).foregroundStyle(.secondary)
                        }
                        if let s = p.status, !s.isEmpty {
                            Text(s).font(.caption).foregroundStyle(.tertiary)
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
        }
    }

    // MARK: - Load
    private func loadOnce() async {
        guard !didLoadOnce else { return }
        didLoadOnce = true
        await reload()
    }

    private func reload() async {
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
