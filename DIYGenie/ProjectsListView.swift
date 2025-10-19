import SwiftUI

struct ProjectsListView: View {
    @State private var projects: [Project] = []
    @State private var isLoading: Bool = false
    @State private var errorMessage: String? = nil
    private let service = ProjectsService.shared
    private let telemetry = TelemetryService()

    var body: some View {
        NavigationStack {
            Group {
                if isLoading && projects.isEmpty {
                    ProgressView("Loading…")
                } else if projects.isEmpty {
                    VStack(spacing: 8) {
                        Label {
                            Text("No Projects")
                        } icon: {
                            Image(systemName: "tray")
                        }
                        Text("Pull to refresh")
                            .foregroundStyle(.secondary)
                            .font(.subheadline)
                    }
                } else {
                    List {
                        ForEach(projects) { project in
                            HStack {
                                Text(project.title.isEmpty ? project.id : project.title)
                                    .lineLimit(1)
                                Spacer()
                            }
                            .accessibilityLabel(project.title.isEmpty ? project.id : project.title)
                        }
                        .onDelete(perform: handleDelete)
                    }
                    .refreshable { await loadProjects() }
                }
            }
            .navigationTitle("Projects")
            .task { await loadProjects() }
            .alert("Error", isPresented: Binding(get: { errorMessage != nil }, set: { presented in if !presented { errorMessage = nil } })) {
                Button("OK", role: .cancel) { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "Unknown error")
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    #if DEBUG
                    Button("Add (debug)") {
                        Task {
                            do {
                                let created = try await ProjectsService.shared.create(
                                    name: "iOS Debug \(Int(Date().timeIntervalSince1970))",
                                    goal: "smoke test",
                                    userId: UserSession.shared.userId
                                )
                                // optional telemetry if id is returned
                                _ = try? await telemetry.log(event: "project_created", metadata: ["id": created.id])
                                // refresh list
                                let refreshed = try await ProjectsService.shared.list(userId: UserSession.shared.userId)
                                await MainActor.run { projects = refreshed }
                            } catch {
                                await MainActor.run {
                                    errorMessage = error.localizedDescription
                                }
                            }
                        }
                    }
                    .accessibilityLabel("Add debug project")
                    #endif
                }
            }
        }
    }

    @MainActor
    private func loadProjects() async {
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            let fetched: [Project] = try await service.list(userId: UserSession.shared.userId)
            projects = fetched
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }

    private func handleDelete(at offsets: IndexSet) {
        Task { @MainActor in
            for index in offsets.sorted(by: >) {
                guard projects.indices.contains(index) else { continue }
                let project = projects[index]
                do {
                    let resp = try await service.deleteProject(id: project.id)
                    if resp.success {
                        projects.remove(at: index)
                        _ = try? await telemetry.log(event: "project_deleted", metadata: ["id": project.id])
                    } else {
                        errorMessage = "Failed to delete project."
                    }
                } catch {
                    errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
                }
            }
        }
    }
}

#Preview { ProjectsListView() }

