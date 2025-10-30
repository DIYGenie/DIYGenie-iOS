//
//  ProjectDetailsView.swift
//  DIYGenieApp
//

import SwiftUI

struct ProjectDetailsView: View {
    let project: Project
    let userId: String

    @State private var plan: PlanResponse?
    @State private var isLoading = true
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var expandedSection: String? = nil

    private let gradientTop = Color(red: 28/255, green: 26/255, blue: 40/255)
    private let gradientBottom = Color(red: 58/255, green: 35/255, blue: 110/255)
    private let accentStart = Color(red: 115/255, green: 73/255, blue: 224/255)
    private let accentEnd = Color(red: 146/255, green: 86/255, blue: 255/255)

    var body: some View {
        ZStack {
            LinearGradient(colors: [gradientTop, gradientBottom],
                           startPoint: .topLeading,
                           endPoint: .bottomTrailing)
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    // MARK: - Header
                    HStack {
                        Button(action: { }) {
                            Image(systemName: "chevron.left")
                                .foregroundColor(.white)
                                .font(.system(size: 18, weight: .semibold))
                        }
                        Spacer()
                    }

                    Text(project.name ?? "Project")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)

                    if let goal = project.goal {
                        Text(goal)
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.7))
                            .padding(.bottom, 10)
                    }

                    // MARK: - Preview Image
                    if let imageURL = project.previewURL ?? project.inputImageURL,
                       let url = URL(string: imageURL) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .empty:
                                ProgressView()
                                    .frame(height: 220)
                                    .frame(maxWidth: .infinity)
                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFill()
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 220)
                                    .clipped()
                                    .cornerRadius(18)
                                    .overlay(
                                        LinearGradient(colors: [.black.opacity(0.0), .black.opacity(0.25)],
                                                       startPoint: .center, endPoint: .bottom)
                                            .cornerRadius(18)
                                    )
                            case .failure:
                                Color.black.opacity(0.2)
                                    .frame(height: 220)
                                    .cornerRadius(18)
                            @unknown default:
                                EmptyView()
                            }
                        }
                    }

                    if isLoading {
                        ProgressView("Loading Plan…")
                            .tint(.white)
                            .foregroundColor(.white)
                            .padding(.top, 30)
                    } else if let plan = plan {
                        // MARK: - Plan Sections
                        Group {
                            collapsibleSection(title: "Steps", systemImage: "list.number") {
                                VStack(alignment: .leading, spacing: 8) {
                                    ForEach(plan.steps?.prefix(3) ?? [], id: \.self) { step in
                                        Text("• \(step)")
                                            .foregroundColor(.white.opacity(0.9))
                                            .font(.subheadline)
                                    }
                                }
                            }

                            collapsibleSection(title: "Materials", systemImage: "cube.box") {
                                VStack(alignment: .leading, spacing: 6) {
                                    ForEach(plan.materials?.prefix(3) ?? [], id: \.self) { item in
                                        Text("• \(item)")
                                            .foregroundColor(.white.opacity(0.9))
                                            .font(.subheadline)
                                    }
                                }
                            }

                            collapsibleSection(title: "Tools", systemImage: "hammer") {
                                VStack(alignment: .leading, spacing: 6) {
                                    ForEach(plan.tools?.prefix(3) ?? [], id: \.self) { tool in
                                        Text("• \(tool)")
                                            .foregroundColor(.white.opacity(0.9))
                                            .font(.subheadline)
                                    }
                                }
                            }

                            if let cost = plan.estimatedCost {
                                collapsibleSection(title: "Estimated Cost", systemImage: "dollarsign.circle") {
                                    Text("$\(Int(cost)) estimated total")
                                        .foregroundColor(.white.opacity(0.9))
                                        .font(.subheadline)
                                }
                            }
                        }

                        // MARK: - CTA
                        NavigationLink(destination: DetailedBuildPlanView(projectId: project.id, userId: userId)) {
                            Text("Open Detailed Build Plan")
                                .font(.system(size: 18, weight: .bold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    LinearGradient(colors: [accentStart, accentEnd],
                                                   startPoint: .leading,
                                                   endPoint: .trailing)
                                )
                                .cornerRadius(16)
                                .foregroundColor(.white)
                                .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 5)
                        }
                        .padding(.top, 20)
                    }

                    Spacer(minLength: 60)
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
            }
        }
        .navigationBarBackButtonHidden(true)
        .task { await fetchPlan() }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }

    // MARK: - Networking
    private func fetchPlan() async {
        let service = ProjectsService(userId: userId)
        do {
            plan = try await service.fetchPlan(projectId: project.id)
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
        isLoading = false
    }

    // MARK: - Collapsible Section
    private func collapsibleSection<Content: View>(
        title: String,
        systemImage: String,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(.easeInOut) {
                    expandedSection = expandedSection == title ? nil : title
                }
            } label: {
                HStack {
                    Label(title, systemImage: systemImage)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                    Spacer()
                    Image(systemName: expandedSection == title ? "chevron.up" : "chevron.down")
                        .foregroundColor(.white.opacity(0.7))
                }
                .padding()
                .background(Color.white.opacity(0.07))
                .cornerRadius(12)
            }

            if expandedSection == title {
                VStack(alignment: .leading, spacing: 8) {
                    content()
                        .padding(.horizontal)
                        .padding(.bottom, 12)
                }
                .background(Color.white.opacity(0.04))
                .cornerRadius(12)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.85), value: expandedSection)
    }
}
