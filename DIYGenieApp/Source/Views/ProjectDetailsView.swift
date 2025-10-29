//
//  ProjectDetailsView.swift
//  DIYGenieApp
//

import SwiftUI

/// A detailed view for a single project.
/// Displays before/after images, basic info, and allows viewing the full plan.
struct ProjectDetailsView: View {
    let project: Project

    @State private var plan: PlanResponse?
    @State private var isLoadingPlan = false
    @State private var showPreview = true
    @State private var showDetailedPlan = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var measurements: [Double] = []

    private let projectsService = ProjectsService(userId: "99198c4b-8470-49e2-895c-75593c5aa181")

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // MARK: - Hero Image
                if let url = URL(string: showPreview
                                 ? (project.previewURL ?? "")
                                 : (project.inputImageURL ?? "")) {
                    AsyncImage(url: url) { image in
                        image.resizable().scaledToFill()
                    } placeholder: {
                        Rectangle().fill(Color.gray.opacity(0.2))
                    }
                    .frame(height: 220)
                    .clipped()
                }

                // MARK: - Project Info
                VStack(alignment: .leading, spacing: 6) {
                    Text(project.name ?? "Untitled Project")
                        .font(.title2)
                        .bold()
                    if let goal = project.goal {
                        Text(goal)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal)

                // MARK: - Load Plan Section
                if isLoadingPlan {
                    ProgressView("Loading plan…")
                        .padding(.horizontal)
                } else if let plan = plan {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Plan Overview")
                            .font(.headline)
                        Text(plan.summary ?? "No summary available.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)
                } else {
                    Text("Plan not available yet. Check back later.")
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                }

                Spacer(minLength: 40)
            }
        }
        .navigationTitle("Project Details")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $showDetailedPlan) {
            if let plan = plan {
                DetailedBuildPlanView(plan: plan)
            }
        }
        .onAppear {
            Task { await loadPlan() }
        }
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Info"),
                  message: Text(alertMessage),
                  dismissButton: .default(Text("OK")))
        }
    }

    // MARK: - Load Plan
    @MainActor
    func loadPlan() async {
        isLoadingPlan = true
        do {
            plan = try await projectsService.fetchPlan(projectId: project.id)
        } catch {
            print("Plan not available yet: \(error.localizedDescription)")
        }
        isLoadingPlan = false
    }
}
