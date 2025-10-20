import SwiftUI

struct ProjectsListView: View {
    @State private var projects: [Project] = []
    @State private var isLoading = false
    @State private var error: String?

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView("Loading…")
                } else if let error {
                    VStack(spacing: 8) {
                        Text("Failed to load").font(.headline)
                        Text(error).font(.footnote).foregroundStyle(.secondary).multilineTextAlignment(.center)
                        Button("Retry", action: load)
                    }.padding()
                } else if projects.isEmpty {
                    VStack(spacing: 8) {
                        Text("No projects yet").font(.headline)
                        Text("Create your first DIY plan from the + button.")
                            .font(.footnote).foregroundStyle(.secondary).multilineTextAlignment(.center)
                    }.padding()
                } else {
                    List(projects, id: \.id) { p in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(p.name)
                                .font(.headline)
                            if let goal = p.goal, !goal.isEmpty {
                                Text(goal)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            if let s = p.status, !s.isEmpty {
                                Text(s)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Projects")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { /* present NewProjectView later */ }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .task(priority: .background) {
                await loadAsyncOnce()
            }
        }
    }

    // MARK: - Loaders
    private func load() { Task { await loadAsyncOnce() } }

    @MainActor
    private func loadAsyncOnce() async {
        guard !isLoading else { return }
        isLoading = true; defer { isLoading = false }
        do {
            let uid = UserSession.shared.userId
            projects = try await ProjectsService.shared.list(userId: uid)
            error = nil
        } catch {
            self.error = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }
}
