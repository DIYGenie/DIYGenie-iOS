//
//  ProjectsListView.swift
//  DIYGenieApp
//

import SwiftUI

struct ProjectsListView: View {
    // MARK: - Services / State
    private let service = ProjectsService(
        userId: UserSession.currentUserID()
    )
    
    @State private var projects: [Project] = []
    @State private var loadTask: Task<Void, Never>?
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorText = ""
    
    var body: some View {
        NavigationStack {
            Group {
                if isLoading && projects.isEmpty {
                    ProgressView().tint(.white)
                } else if projects.isEmpty {
                    VStack(spacing: 12) {
                        Text("No projects yet")
                            .font(.headline)
                            .foregroundColor(Color("TextPrimary"))
                        Text("Create your first DIY Genie project to get started.")
                            .font(.subheadline)
                            .foregroundColor(Color("TextSecondary"))
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(projects, id: \.id) { p in
                            NavigationLink {
                                ProjectDetailsView(project: p)
                            } label: {
                                ProjectCard(project: p)
                            }
                            .listRowBackground(Color.clear)
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Projects")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        refresh()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .disabled(isLoading)
                }
            }
            .task {
                // initial load (cancellable)
                refresh()
            }
            .refreshable {
                refresh()
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorText)
            }
            .background(
                LinearGradient(gradient: Gradient(colors: [Color("BGStart"), Color("BGEnd")]),
                               startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()
            )
        }
    }
    
    // MARK: - Loading
    private func refresh() {
        loadTask?.cancel()
        
        isLoading = true
        loadTask = Task { @MainActor in
            defer { isLoading = false }
            do {
                try? await Task.sleep(nanoseconds: 120_000_000)
                try Task.checkCancellation()   // will jump to catch below on cancel
                let rows = try await service.fetchProjects()
                self.projects = rows
            } catch is CancellationError {
                return   // user pulled to refresh again; ignore
            } catch {
                if !error.isURLCancelled {
                    print("Error loading projects:", error.localizedDescription)
                    self.errorText = "Failed to load projects."
                    self.showError = true
                }
            }
        }
    }
}
