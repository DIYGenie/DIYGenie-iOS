//
//  ProjectDetailsView.swift
//  DIYGenieApp
//

import SwiftUI

struct ProjectDetailsView: View {
    let project: Project
    @State private var plan: PlanResponse?
    @State private var shareImage: UIImage?
    @State private var showingPreview = true
    @State private var showShareSheet = false
    @State private var alertMessage = ""
    @State private var showAlert = false
    @State private var isLoading = false

    private let service = ProjectsService(
        userId: UserDefaults.standard.string(forKey: "user_id") ?? "demo"
    )

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {

                // MARK: - Header
                VStack(alignment: .leading, spacing: 4) {
                    Text(project.name)
                        .font(.largeTitle.bold())
                        .foregroundColor(.white)
                    Text(project.goal)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                }
                .padding(.horizontal, 20)

                // MARK: - Image Preview
                if let imageURL = currentImageURL {
                    AsyncImage(url: imageURL) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFit()
                                .cornerRadius(16)
                                .shadow(radius: 6)
                        case .failure(_):
                            placeholderImage("Failed to load image")
                        default:
                            ProgressView().tint(.white)
                        }
                    }
                    .padding(.horizontal, 20)
                } else {
                    placeholderImage("No image available")
                }

                // MARK: - Plan Content
                if let plan = plan {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("AI Project Plan")
                            .font(.title3.bold())
                            .foregroundColor(.white)
                        if let summary = plan.summary {
                            Text(summary)
                                .foregroundColor(.white.opacity(0.9))
                        }

                        if let steps = plan.steps, !steps.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                ForEach(steps, id: \.self) { step in
                                    Text("• \(step)")
                                        .foregroundColor(.white.opacity(0.9))
                                }
                            }
                        }

                        if let materials = plan.materials, !materials.isEmpty {
                            Text("Materials: \(materials.joined(separator: ", "))")
                                .foregroundColor(.white.opacity(0.8))
                        }

                        if let tools = plan.tools, !tools.isEmpty {
                            Text("Tools: \(tools.joined(separator: ", "))")
                                .foregroundColor(.white.opacity(0.8))
                        }

                        if let cost = plan.estimatedCost {
                            Text("Estimated Cost: $\(Int(cost))")
                                .foregroundColor(.white)
                        }
                    }
                    .padding(.horizontal, 20)
                } else {
                    VStack {
                        if isLoading {
                            ProgressView("Loading Plan...")
                                .tint(.white)
                        } else {
                            Button {
                                Task { await loadPlan() }
                            } label: {
                                primaryButton("Load AI Plan")
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }

                // MARK: - Share Button
                if shareImage != nil {
                    Button {
                        showShareSheet = true
                    } label: {
                        secondaryButton("Share Preview")
                    }
                    .sheet(isPresented: $showShareSheet) {
                        if let image = shareImage {
                            ShareSheet(activityItems: [image])
                        }
                    }
                }
            }
            .padding(.vertical, 24)
        }
        .background(
            LinearGradient(colors: [
                Color(red: 28/255, green: 26/255, blue: 40/255),
                Color(red: 60/255, green: 35/255, blue: 126/255)
            ], startPoint: .topLeading, endPoint: .bottomTrailing)
            .ignoresSafeArea()
        )
        .task { await loadPlan() }
        .alert("Status", isPresented: $showAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(alertMessage)
        }
    }

    // MARK: - Computed: Image URL
    private var currentImageURL: URL? {
        if showingPreview, let urlString = project.preview_url, let url = URL(string: urlString) {
            return url
        } else if let urlString = project.input_image_url, let url = URL(string: urlString) {
            return url
        }
        return nil
    }

    // MARK: - Helpers
    @MainActor
    private func loadPlan() async {
        guard let id = project.id as String? else { return }
        isLoading = true
        do {
            let result = try await service.generatePlanOnly(projectId: id)
            self.plan = result
            alertMessage = "Plan loaded successfully ✅"
        } catch {
            alertMessage = "Failed to load plan: \(error.localizedDescription)"
        }
        isLoading = false
        showAlert = true
    }

    // MARK: - UI Helpers
    private func placeholderImage(_ text: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 40))
                .foregroundColor(.white.opacity(0.5))
            Text(text)
                .font(.caption)
                .foregroundColor(.white.opacity(0.6))
        }
        .frame(maxWidth: .infinity, minHeight: 180)
        .background(Color.white.opacity(0.08))
        .cornerRadius(16)
        .padding(.horizontal, 20)
    }

    private func primaryButton(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 18, weight: .bold))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                LinearGradient(colors: [
                    Color(red: 115/255, green: 73/255, blue: 224/255),
                    Color(red: 146/255, green: 86/255, blue: 255/255)
                ], startPoint: .leading, endPoint: .trailing)
            )
            .foregroundColor(.white)
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.25), radius: 8, x: 0, y: 4)
    }

    private func secondaryButton(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 17, weight: .semibold))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .background(Color.white.opacity(0.08))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
            .foregroundColor(.white)
            .cornerRadius(14)
    }
}

