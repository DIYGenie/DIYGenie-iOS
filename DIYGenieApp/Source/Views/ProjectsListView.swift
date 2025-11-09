//
//  ProjectsListView.swift
//  DIYGenieApp
//

import SwiftUI

struct ProjectsListView: View {
    // MARK: - Services
    private let service = ProjectsService(
        userId: UserDefaults.standard.string(forKey: "user_id") ?? UUID().uuidString
    )

    // MARK: - State
    @State private var projects: [Project] = []
    @State private var isLoading = false
    @State private var errorText: String?
    @State private var showError = false
    @State private var loadTask: Task<Void, Never>?

    var body: some View {
        NavigationView {
            Group {
                if isLoading && projects.isEmpty {
                    ProgressView().tint(.white)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if projects.isEmpty {
                    VStack(spacing: 10) {
                        Text("No projects yet").font(.headline).foregroundColor(.white)
                        Text("Create your first project from the New tab.")
                            .font(.subheadline).foregroundColor(.white.opacity(0.7))
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List(projects) { p in
                        NavigationLink(destination: ProjectDetailsView(project: p)) {
                            ProjectRow(project: p)
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Projects")
        }
        .task { await loadProjects() }
        .refreshable { await loadProjects() }
        .alert(errorText ?? "Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        }
    }

    // MARK: - Data loading
    @MainActor
    private func loadProjects() async {
        loadTask?.cancel()
        isLoading = projects.isEmpty
        errorText = nil

        loadTask = Task {
            do {
                try await Task.sleep(nanoseconds: 150_000_000)
                try Task.checkCancellation()

                let rows = try await service.fetchProjects()
                await MainActor.run {
                    self.projects = rows
                    self.isLoading = false
                }
            } catch {
                if error.isURLCancelled { return }
                await MainActor.run {
                    self.isLoading = false
                    self.errorText = "Failed to load projects."
                    self.showError = true
                    print("Error loading projects:", error.localizedDescription)
                }
            }
        }
        await loadTask?.value
    }
}

// MARK: - Row

private struct ProjectRow: View {
    let project: Project

    // Prefer preview, else input image
    private var thumbURL: URL? {
        if let s = project.preview_url, let u = URL(string: s) { return u }
        if let s = project.input_image_url, let u = URL(string: s) { return u }
        return nil
    }

    var body: some View {
        HStack(spacing: 12) {
            // Thumbnail
            Group {
                if let url = thumbURL {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .empty:
                            ZStack {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.white.opacity(0.06))
                                ProgressView()
                            }
                        case .success(let img):
                            img.resizable().scaledToFill()
                        case .failure:
                            placeholder
                        @unknown default:
                            placeholder
                        }
                    }
                    .frame(width: 72, height: 72)
                    .clipped()
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.08), lineWidth: 1)
                    )
                } else {
                    placeholder
                        .frame(width: 72, height: 72)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.08), lineWidth: 1)
                        )
                }
            }

            // Texts
            VStack(alignment: .leading, spacing: 4) {
                Text(project.name)
                    .font(.headline)
                if let g = project.goal, !g.isEmpty {
                    Text(g)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                if project.preview_url != nil {
                    Text("Has Preview")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 8).padding(.vertical, 4)
                        .background(Color("Accent").opacity(0.85))
                        .cornerRadius(8)
                }
            }
        }
        .padding(.vertical, 4)
    }

    private var placeholder: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.06))
            Image(systemName: "photo.on.rectangle")
                .imageScale(.large)
                .foregroundColor(.white.opacity(0.6))
        }
    }
}

