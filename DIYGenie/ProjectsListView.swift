import SwiftUI

struct ProjectsListView: View {
    @State private var projects: [Project] = []
    @State private var isLoading = false
    @State private var error: String?
    @State private var didLoad = false
    @State private var showCreate = false

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView("Loading…")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let error {
                    VStack(spacing: 8) {
                        Text("Failed to load").font(.headline)
                        Text(error).font(.footnote).foregroundStyle(.secondary).multilineTextAlignment(.center)
                        Button("Retry") { Task { await load() } }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if projects.isEmpty {
                    VStack(spacing: 8) {
                        Text("No projects yet").font(.headline)
                        Text("Tap + to create your first DIY plan.")
                            .font(.footnote).foregroundStyle(.secondary).multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List(projects, id: \.id) { p in
                        NavigationLink {
                            ProjectDetailView(project: p)
                        } label: {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(p.name).font(.headline)
                                if let s = p.status, !s.isEmpty {
                                    Text(s).font(.caption).foregroundStyle(.secondary)
                                }
                                if let g = p.goal, !g.isEmpty {
                                    Text(g).font(.caption2).foregroundStyle(.secondary).lineLimit(1)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
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

    // MARK: - Loading
    private func loadOnce() async {
        guard !didLoad else { return }
        didLoad = true
        await load()
    }

    @MainActor
    private func setState(isLoading: Bool, error: String?) {
        self.isLoading = isLoading
        self.error = error
    }

    private func load() async {
        await setState(isLoading: true, error: nil)
        do {
            let userId = UserSession.shared.userId
            let items = try await ProjectsService().list(userId: userId)
            await MainActor.run { self.projects = items; self.isLoading = false }
        } catch {
            await setState(isLoading: false, error: error.localizedDescription)
        }
    }
}
// ✅ Ready to Build
