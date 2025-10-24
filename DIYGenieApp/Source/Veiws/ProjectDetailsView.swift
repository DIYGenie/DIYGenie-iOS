// ProjectDetailsView.swift
import SwiftUI

struct ProjectDetailsView: View {
    let project: Project

    @State private var plan: PlanResponse?
    @State private var isLoadingPlan = false
    @State private var showPreview = true
    @State private var alertMessage = ""
    @State private var showAlert = false

    private let projectsService = ProjectsService(userId: "99198c4b-8470-49e2-895c-75593c5aa181")

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Hero image: show segmented control if preview exists.
                if let previewURL = project.previewURL {
                    Picker("", selection: $showPreview) {
                        Text("Preview").tag(true)
                        Text("Original").tag(false)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.top)
                    let heroURL = showPreview ? previewURL : (project.inputImageURL ?? previewURL)
                    AsyncImage(url: heroURL) { image in
                        image.resizable().scaledToFill()
                    } placeholder: {
                        Rectangle().fill(Color.gray.opacity(0.2))
                    }
                    .frame(height: 220)
                    .clipped()
                    .cornerRadius(12)
                } else if let inputURL = project.inputImageURL {
                    // Only original image available.
                    AsyncImage(url: inputURL) { image in
                        image.resizable().scaledToFill()
                    } placeholder: {
                        Rectangle().fill(Color.gray.opacity(0.2))
                    }
                    .frame(height: 220)
                    .clipped()
                    .cornerRadius(12)
                }

                Text(project.name)
                    .font(.title2.bold())
                    .padding(.top, 8)

                if let plan = plan {
                    // Overview (first step as summary)
                    if let firstStep = plan.steps.first {
                        Section(header: Text("Overview").font(.headline)) {
                            Text(firstStep)
                                .foregroundColor(.primary)
                        }
                        .padding(.top, 12)
                    }

                    // Materials + Tools
                    Section(header: Text("Materials + Tools").font(.headline)) {
                        VStack(alignment: .leading, spacing: 4) {
                            if !plan.materials.isEmpty {
                                Text("Materials:")
                                    .fontWeight(.semibold)
                                ForEach(plan.materials, id: \.self) { item in
                                    Text("• \(item)")
                                }
                            }
                            if !plan.tools.isEmpty {
                                Text("Tools:")
                                    .fontWeight(.semibold)
                                    .padding(.top, plan.materials.isEmpty ? 0 : 8)
                                ForEach(plan.tools, id: \.self) { item in
                                    Text("• \(item)")
                                }
                            }
                        }
                    }
                    .padding(.top, 12)

                    // Steps with numbers
                    Section(header: Text("Steps").font(.headline)) {
                        ForEach(Array(plan.steps.enumerated()), id: \.offset) { index, step in
                            HStack(alignment: .top, spacing: 8) {
                                Text("\(index + 1).")
                                    .fontWeight(.bold)
                                Text(step)
                                    .multilineTextAlignment(.leading)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .padding(.top, 12)
                } else if isLoadingPlan {
                    ProgressView("Fetching plan…")
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 12)
                } else {
                    Text("Plan not available yet. Check back later.")
                        .foregroundColor(.secondary)
                        .padding(.top, 12)
                }

                Spacer(minLength: 40)
            }
            .padding()
        }
        .navigationTitle("Project Details")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            Task { await loadPlan() }
        }
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Error"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
    }

    /// Fetch the full plan for this project.
    @MainActor
    private func loadPlan() async {
        isLoadingPlan = true
        do {
            plan = try await projectsService.fetchPlan(projectId: project.id)
        } catch {
            alertMessage = error.localizedDescription
            showAlert = true
        }
        isLoadingPlan = false
    }
}
