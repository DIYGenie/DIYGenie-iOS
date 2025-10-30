//
//  DetailedBuildPlanView.swift
//  DIYGenieApp
//

import SwiftUI

struct DetailedBuildPlanView: View {
    let projectId: String
    let userId: String

    @State private var plan: PlanResponse?
    @State private var isLoading = true
    @State private var errorMessage: String?

    private let gradientTop = Color(red: 28/255, green: 26/255, blue: 40/255)
    private let gradientBottom = Color(red: 60/255, green: 35/255, blue: 126/255)
    private let accentStart = Color(red: 115/255, green: 73/255, blue: 224/255)
    private let accentEnd = Color(red: 146/255, green: 86/255, blue: 255/255)

    var body: some View {
        ZStack {
            LinearGradient(colors: [gradientTop, gradientBottom],
                           startPoint: .topLeading,
                           endPoint: .bottomTrailing)
                .ignoresSafeArea()

            if isLoading {
                ProgressView("Loading Build Plan…")
                    .tint(.white)
                    .foregroundColor(.white)
            } else if let plan = plan {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Detailed Build Plan")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)

                        if let steps = plan.steps, !steps.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                ForEach(steps.indices, id: \.self) { i in
                                    Text("• \(steps[i])")
                                        .foregroundColor(.white.opacity(0.9))
                                }
                            }
                        } else {
                            Text("No steps available yet.")
                                .foregroundColor(.white.opacity(0.7))
                        }

                        if let materials = plan.materials, !materials.isEmpty {
                            glassCard {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Materials")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                    ForEach(materials, id: \.self) { mat in
                                        Text("• \(mat)")
                                            .foregroundColor(.white.opacity(0.9))
                                    }
                                }
                            }
                        }

                        if let tools = plan.tools, !tools.isEmpty {
                            glassCard {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Tools")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                    ForEach(tools, id: \.self) { tool in
                                        Text("• \(tool)")
                                            .foregroundColor(.white.opacity(0.9))
                                    }
                                }
                            }
                        }

                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 30)
                }
            } else if let error = errorMessage {
                VStack(spacing: 8) {
                    Text("Failed to Load Plan")
                        .font(.headline)
                        .foregroundColor(.white)
                    Text(error)
                        .foregroundColor(.white.opacity(0.7))
                        .font(.subheadline)
                    Button("Retry") {
                        Task { await fetchPlan() }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(accentStart)
                }
            }
        }
        .navigationTitle("Build Plan")
        .toolbarBackground(.hidden)
        .preferredColorScheme(.dark)
        .task { await fetchPlan() }
    }

    // MARK: - Networking
    private func fetchPlan() async {
        isLoading = true
        defer { isLoading = false }
        let service = ProjectsService(userId: userId)
        do {
            plan = try await service.fetchPlan(projectId: projectId)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - UI Helpers
    private func glassCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .padding(16)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18))
            .overlay(RoundedRectangle(cornerRadius: 18)
                .stroke(Color.white.opacity(0.08), lineWidth: 1))
            .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
    }
}
