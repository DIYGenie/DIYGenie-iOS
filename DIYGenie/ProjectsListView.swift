import SwiftUI

struct ProjectsListView: View {
    @State private var projects: [Project] = []
    @State private var isLoading: Bool = false
    @State private var errorMessage: String? = nil
    private let service = ProjectsService()
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
                    Button("Add (debug)") {
                        Task { @MainActor in
                            do {
                                _ = try await service.createProject(title: "iOS Debug", goal: "smoke test")
                                await loadProjects()
                            } catch {
                                let message = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
                                errorMessage = message
                                print("[ProjectsListView] Create project failed: \(message)")
                            }
                        }
                    }
                    .accessibilityLabel("Add debug project")
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
            let fetched: [Project] = try await service.fetchProjects()
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
