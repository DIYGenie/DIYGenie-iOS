//
//  ProjectDetailsView.swift
//  DIYGenieApp
//

import SwiftUI
import UIKit

struct ProjectDetailsView: View {
    let project: Project

    private var background: some View {
        LinearGradient(
            gradient: Gradient(colors: [Color("BGStart"), Color("BGEnd")]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }

    private var originalPhotoURL: URL? {
        project.inputImageURL ?? project.photoUrl.flatMap(URL.init(string:))
    }

    private var previewOrPhotoURL: URL? {
        project.previewURL ?? project.photoUrl.flatMap(URL.init(string:))
    }

    private var isUsingPreviewFallback: Bool {
        project.previewURL == nil && previewOrPhotoURL != nil
    }

    private var estimatedCostText: String? {
        if let numeric = project.estimatedCost {
            let formatter = NumberFormatter()
            formatter.numberStyle = .currency
            formatter.maximumFractionDigits = 0
            return formatter.string(from: NSNumber(value: numeric))
        }

        if let cost = project.planJson?.estimatedCost, !cost.isEmpty {
            return cost
        }
        return nil
    }

    private var durationText: String? {
        project.estimatedDuration ?? project.planJson?.estimatedDuration
    }

    private var skillText: String? {
        project.skillLevelEstimate ?? project.planJson?.skillLevel
    }

    private var areaText: String? {
        if let area = project.metadata?.area {
            return String(format: "%.1f sq units", area)
        }
        return nil
    }

    private var perimeterText: String? {
        if let perimeter = project.metadata?.perimeter {
            return String(format: "%.1f units", perimeter)
        }
        return nil
    }

    var body: some View {
        ZStack {
            background

            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    headerSection

                    statsSection

                    mediaSection

                    planSummarySection

                    NavigationLink {
                        BuildPlanView(plan: project.planJSON)
                    } label: {
                        Text("View Detailed Build Plan")
                            .font(.headline.weight(.semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 18)
                                    .fill(Color("Accent"))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 18)
                                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                    )
                            )
                    }
                    .disabled(project.planJSON == nil)
                    .opacity(project.planJSON == nil ? 0.6 : 1)

                    Spacer(minLength: 32)
                }
                .padding(18)
            }
        }
        .onAppear {
            if let plan = project.planJson {
                print("[ProjectDetailsView] Plan summary: \(plan.summary ?? "<no summary>")")
            }
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(project.name)
                .font(.largeTitle.bold())
                .foregroundColor(.white)
                .multilineTextAlignment(.leading)

            if let goal = project.goal, !goal.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Text(goal)
                    .foregroundColor(Color.white.opacity(0.85))
                    .font(.body)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var statsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Project Summary")
                .font(.title3.weight(.semibold))
                .foregroundColor(.white)

            VStack(spacing: 10) {
                if let budget = project.budget, !budget.isEmpty {
                    statRow(title: "Budget", value: budget)
                }
                if let cost = estimatedCostText {
                    statRow(title: "Estimated Cost", value: cost)
                }
                if let duration = durationText {
                    statRow(title: "Estimated Duration", value: duration)
                }
                if let skill = skillText {
                    statRow(title: "Skill Level", value: skill.capitalized)
                }
                if let area = areaText {
                    statRow(title: "Area", value: area)
                }
                if let perimeter = perimeterText {
                    statRow(title: "Perimeter", value: perimeter)
                }
            }
            .padding(14)
            .background(Color.white.opacity(0.08))
            .cornerRadius(14)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func statRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.75))
            Spacer()
            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.white)
        }
    }

    private var mediaSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Images")
                .font(.title3.weight(.semibold))
                .foregroundColor(.white)

            if let original = originalPhotoURL {
                mediaCard(title: "Original Photo", url: original)
            }

            if let preview = previewOrPhotoURL {
                mediaCard(title: "Preview Image", url: preview)

                if isUsingPreviewFallback {
                    Text("Preview not available; showing project photo instead.")
                        .font(.footnote)
                        .foregroundColor(.yellow.opacity(0.9))
                }
            } else {
                Text("Preview not available")
                    .font(.footnote)
                    .foregroundColor(.yellow.opacity(0.9))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func mediaCard(title: String, url: URL) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundColor(.white)

            ProjectMediaView(url: url)
        }
    }

    private var planSummarySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Plan Overview")
                .font(.title3.weight(.semibold))
                .foregroundColor(.white)

            if let plan = project.planJSON {
                if let summary = plan.summary, !summary.isEmpty {
                    Text(summary)
                        .foregroundColor(.white.opacity(0.85))
                        .font(.body)
                        .padding(14)
                        .background(Color.white.opacity(0.08))
                        .cornerRadius(14)
                }

                if let materials = project.materials ?? plan.materials.map({ $0.name }), !materials.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Materials")
                            .font(.headline)
                            .foregroundColor(.white)
                        ForEach(materials, id: \.self) { item in
                            Text("• \(item)")
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                    .padding(14)
                    .background(Color.white.opacity(0.06))
                    .cornerRadius(14)
                }
            } else {
                Text("Plan is generating. Check back in a moment.")
                    .foregroundColor(.white.opacity(0.75))
                    .font(.body)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct ProjectMediaView: View {
    let url: URL

    var body: some View {
        Group {
            if let image = localImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    case .failure:
                        placeholder
                    case .empty:
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    @unknown default:
                        placeholder
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 260)
        .clipped()
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.35), radius: 8, x: 0, y: 4)
    }

    private var placeholder: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.08))
            Image(systemName: "photo.on.rectangle")
                .font(.system(size: 36, weight: .semibold))
                .foregroundColor(.white.opacity(0.7))
        }
    }

    private var localImage: UIImage? {
        guard url.isFileURL else { return nil }
        return UIImage(contentsOfFile: url.path)
    }
}
