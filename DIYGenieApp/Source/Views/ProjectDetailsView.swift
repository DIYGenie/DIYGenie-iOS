//
//  ProjectDetailsView.swift
//  DIYGenieApp
//

import SwiftUI
import UIKit

struct ProjectDetailsView: View {
    let project: Project

    var body: some View {
        ZStack {
            // Match the NewProjectView gradient-style background so it isn't just black
            LinearGradient(
                gradient: Gradient(colors: [Color("BGStart"), Color("BGEnd")]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(project.name)
                            .font(.largeTitle.bold())
                            .foregroundColor(.white)
                        if let goal = project.goal, !goal.isEmpty {
                            Text(goal)
                                .foregroundColor(Color.white.opacity(0.8))
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    VStack(alignment: .leading, spacing: 8) {
                        if let budget = project.budget {
                            Text("Budget: \(budget)")
                        }
                        if let skill = project.skillLevel {
                            Text("Skill level: \(skill)")
                        }
                        if let status = project.previewStatus {
                            Text("Status: \(status)")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.75))
                        }
                        Text("Project ID: \(project.id)")
                            .font(.footnote)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color.white.opacity(0.08))
                    .cornerRadius(16)

                    if let mediaURL = project.previewURL ?? project.inputImageURL {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Preview")
                                .font(.headline)
                                .foregroundColor(.white)
                            ProjectMediaView(urlString: mediaURL)
                        }
                    }

                    PlanSection(plan: project.planJson, completedSteps: project.completedSteps ?? [])

                    Spacer(minLength: 32)
                }
                .padding(18)
            }
        }
    }
}

// MARK: - Subviews

private struct ProjectMediaView: View {
    let urlString: String

    var body: some View {
        Group {
            if let image = localImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } else if let url = remoteURL {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    case .failure:
                        placeholder
                    case .empty:
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    @unknown default:
                        placeholder
                    }
                }
            } else {
                placeholder
            }
        }
        .frame(maxWidth: .infinity)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.08), lineWidth: 1))
        .shadow(color: .black.opacity(0.35), radius: 8, x: 0, y: 4)
    }

    private var placeholder: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(Color.white.opacity(0.08))
            .frame(height: 220)
            .overlay(
                Image(systemName: "photo.on.rectangle")
                    .font(.system(size: 36, weight: .semibold))
                    .foregroundColor(.white.opacity(0.7))
            )
    }

    private var url: URL? {
        URL(string: urlString)
    }

    private var localImage: UIImage? {
        guard let url = url, url.isFileURL else { return nil }
        return UIImage(contentsOfFile: url.path)
    }

    private var remoteURL: URL? {
        guard let url = url, !url.isFileURL else { return nil }
        return url
    }
}

private struct PlanSection: View {
    let plan: PlanResponse?
    let completedSteps: [Int]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("AI Plan")
                .font(.title3.weight(.semibold))
                .foregroundColor(.white)

            if let plan {
                if let summary = plan.summary, !summary.isEmpty {
                    Text(summary)
                        .font(.body)
                        .foregroundColor(.white.opacity(0.85))
                }

                if !plan.materials.isEmpty {
                    sectionHeader("Materials")
                    bulletList(plan.materials)
                }

                if !plan.tools.isEmpty {
                    sectionHeader("Tools")
                    bulletList(plan.tools)
                }

                if let estimate = plan.estimatedCost {
                    sectionHeader("Estimated Cost")
                    Text("$\(Int(estimate))")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(12)
                }

                if !plan.steps.isEmpty {
                    sectionHeader("Steps")
                    let completed = Set(completedSteps)
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(Array(plan.steps.enumerated()), id: \.0) { index, step in
                            HStack(alignment: .top, spacing: 10) {
                                Image(systemName: completed.contains(index) ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(completed.contains(index) ? .green : .white.opacity(0.6))
                                    .font(.system(size: 18, weight: .medium))
                                Text(step)
                                    .foregroundColor(.white.opacity(0.9))
                                    .font(.body)
                            }
                        }
                    }
                    .padding(14)
                    .background(Color.white.opacity(0.08))
                    .cornerRadius(14)
                }
            } else {
                Text("Plan is generating. Check back in a moment.")
                    .foregroundColor(.white.opacity(0.75))
                    .font(.body)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.06))
        .cornerRadius(18)
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.headline.weight(.semibold))
            .foregroundColor(.white)
    }

    private func bulletList(_ items: [String]) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(items, id: \.self) { item in
                HStack(alignment: .top, spacing: 8) {
                    Circle()
                        .fill(Color.white.opacity(0.6))
                        .frame(width: 6, height: 6)
                        .padding(.top, 6)
                    Text(item)
                        .foregroundColor(.white.opacity(0.85))
                        .font(.body)
                }
            }
        }
        .padding(14)
        .background(Color.white.opacity(0.08))
        .cornerRadius(14)
    }
}
