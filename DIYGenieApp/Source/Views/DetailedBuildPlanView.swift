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
    @State private var completedSteps: Set<Int> = []

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

            if isLoading {
                ProgressView("Loading Build Plan…")
                    .tint(.white)
                    .foregroundColor(.white)
            } else if let plan = plan {
                ScrollView {
                    VStack(alignment: .leading, spacing: 22) {

                        // MARK: Header
                        HStack {
                            Button(action: { }) {
                                Image(systemName: "chevron.left")
                                    .foregroundColor(.white)
                                    .font(.system(size: 18, weight: .semibold))
                            }
                            Spacer()
                        }

                        Text(plan.title ?? "Detailed Build Plan")
                            .font(.system(size: 30, weight: .bold))
                            .foregroundColor(.white)
                        if let summary = plan.summary ?? plan.description {
                            Text(summary)
                                .foregroundColor(.white.opacity(0.7))
                                .font(.subheadline)
                                .padding(.bottom, 10)
                        }

                        // MARK: Progress bar
                        if let total = plan.steps?.count, total > 0 {
                            let progress = Double(completedSteps.count) / Double(total)
                            VStack(alignment: .leading) {
                                ProgressView(value: progress)
                                    .tint(accentEnd)
                                Text("\(completedSteps.count) of \(total) steps complete")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.7))
                            }
                        }

                        // MARK: Steps Section
                        if let steps = plan.steps {
                            sectionHeader("Step-by-Step Guide", icon: "list.number")
                            glassCard {
                                VStack(alignment: .leading, spacing: 10) {
                                    ForEach(steps.indices, id: \.self) { i in
                                        HStack(alignment: .top, spacing: 8) {
                                            Button {
                                                toggleStep(i)
                                            } label: {
                                                Image(systemName: completedSteps.contains(i)
                                                      ? "checkmark.circle.fill"
                                                      : "circle")
                                                    .foregroundColor(completedSteps.contains(i) ? accentEnd : .white.opacity(0.6))
                                            }
                                            Text(steps[i])
                                                .foregroundColor(.white.opacity(0.9))
                                                .strikethrough(completedSteps.contains(i))
                                                .animation(.easeInOut, value: completedSteps)
                                        }
                                    }
                                }
                            }
                        }

                        // MARK: Materials
                        if let materials = plan.materials, !materials.isEmpty {
                            sectionHeader("Materials", icon: "cube.box")
                            glassCard {
                                VStack(alignment: .leading, spacing: 8) {
                                    ForEach(materials, id: \.self) { m in
                                        Text("• \(m)")
                                            .foregroundColor(.white.opacity(0.9))
                                    }
                                }
                            }
                        }

                        // MARK: Tools
                        if let tools = plan.tools, !tools.isEmpty {
                            sectionHeader("Tools", icon: "hammer")
                            glassCard {
                                VStack(alignment: .leading, spacing: 8) {
                                    ForEach(tools, id: \.self) { t in
                                        Text("• \(t)")
                                            .foregroundColor(.white.opacity(0.9))
                                    }
                                }
                            }
                        }

                        // MARK: Cost
                        if let cost = plan.estimatedCost {
                            sectionHeader("Estimated Cost", icon: "dollarsign.circle")
                            glassCard {
                                Text("$\(Int(cost)) estimated total")
                                    .foregroundColor(.white.opacity(0.9))
                                    .font(.headline)
                            }
                        }

                        Spacer(minLength: 60)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                }
            } else if let error = errorMessage {
                VStack(spacing: 12) {
                    Text("Failed to Load Plan")
                        .font(.headline)
                        .foregroundColor(.white)
                    Text(error)
                        .foregroundColor(.white.opacity(0.7))
                    Button("Retry") {
                        Task { await fetchPlan() }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(accentStart)
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .task { await fetchPlan() }
        .preferredColorScheme(.dark)
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
    private func sectionHeader(_ title: String, icon: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(accentEnd)
            Text(title)
                .font(.headline)
                .foregroundColor(.white)
            Spacer()
        }
        .padding(.top, 4)
    }

    private func glassCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .padding(16)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18))
            .overlay(RoundedRectangle(cornerRadius: 18)
                .stroke(Color.white.opacity(0.08), lineWidth: 1))
            .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
    }

    private func toggleStep(_ index: Int) {
        if completedSteps.contains(index) {
            completedSteps.remove(index)
        } else {
            completedSteps.insert(index)
        }
    }
}
