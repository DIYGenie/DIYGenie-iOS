//
//  ProjectDetailsView.swift
//  DIYGenieApp
//

import SwiftUI
import UIKit

struct ProjectDetailsView: View {
    let project: Project

    // MARK: - Derived status

    private var statusText: String {
        if project.planJson != nil {
            return "Plan ready"
        }

        if let status = project.previewStatus, !status.isEmpty {
            switch status.lowercased() {
            case "pending", "queued":
                return "Generating…"
            case "error", "failed":
                return "Preview failed"
            default:
                return status.capitalized
            }
        }

        return "Draft"
    }

    private var statusColor: Color {
        if project.planJson != nil {
            return Color.green
        }
        if let status = project.previewStatus?.lowercased() {
            if status == "error" || status == "failed" {
                return Color.red
            }
            if status == "pending" || status == "queued" {
                return Color.yellow
            }
        }
        return Color.white.opacity(0.8)
    }

    private var hasPreview: Bool {
        project.previewURL != nil
    }

    private var hasInputPhoto: Bool {
        project.inputImageURL != nil
    }

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

                    headerSection

                    metaSection

                    if hasPreview || hasInputPhoto {
                        mediaSection
                    }

                    PlanSection(plan: project.planJson, completedSteps: project.completedSteps ?? [])

                    // Full build plan button
                    if project.planJson != nil {
                        NavigationLink {
                            DetailedBuildPlanView(
                                plan: project.planJson,
                                completedSteps: project.completedSteps ?? []
                            )
                        } label: {
                            Text("Open full build plan")
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
                        .padding(.top, 8)
                    }

                    Spacer(minLength: 32)
                }
                .padding(18)
            }
        }
    }

    // MARK: - Sections

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Top row: name + status pill
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Text(project.name)
                    .font(.largeTitle.bold())
                    .foregroundColor(.white)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                Spacer(minLength: 0)

                Text(statusText)
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.black.opacity(0.9))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(statusColor.opacity(0.92))
                    )
            }

            if let goal = project.goal, !goal.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Text(goal)
                    .foregroundColor(Color.white.opacity(0.85))
                    .font(.body)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var metaSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                if let budget = project.budget, !budget.isEmpty {
                    pillLabel(title: budget, systemName: "dollarsign.circle")
                }

                if let skill = project.skillLevel, !skill.isEmpty {
                    pillLabel(title: skill, systemName: "hammer")
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                if let status = project.previewStatus, !status.isEmpty {
                    Text("Preview status: \(status)")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.75))
                }

                Text("Project ID: \(project.id)")
                    .font(.footnote.monospaced())
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color.white.opacity(0.08))
        .cornerRadius(16)
    }

    private var mediaSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Text(hasPreview ? "AI Preview" : "Room Photo")
                    .font(.headline)
                    .foregroundColor(.white)

                if hasPreview, hasInputPhoto {
                    Text("+ original photo")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.6))
                }
            }

            if let mediaURL = project.previewURL ?? project.inputImageURL {
                ProjectMediaView(urlString: mediaURL)
            }

            if hasPreview {
                Text("This is an AI-generated visualization based on your goal and room photo.")
                    .font(.footnote)
                    .foregroundColor(.white.opacity(0.7))
            } else if hasInputPhoto {
                Text("Preview will be generated from this photo and your project details.")
                    .font(.footnote)
                    .foregroundColor(.white.opacity(0.7))
            }
        }
    }

    // MARK: - Small UI helpers

    private func pillLabel(title: String, systemName: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: systemName)
                .imageScale(.small)
            Text(title)
                .font(.footnote.weight(.semibold))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.white.opacity(0.12))
        .foregroundColor(.white)
        .clipShape(Capsule())
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
                    .scaledToFill()
            } else if let url = remoteURL {
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
            } else {
                placeholder
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 260) // keep the media card at a sane height
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
                planContents(for: plan)
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

    @ViewBuilder
    private func planContents(for plan: PlanResponse) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            if let summary = plan.summary, !summary.isEmpty {
                Text(summary)
                    .font(.body)
                    .foregroundColor(.white.opacity(0.85))
            }

            infoRows(for: plan)

            materialsSection(for: plan.materials)

            toolsSection(for: plan.tools)

            if let breakdown = plan.costBreakdown {
                sectionHeader("Cost breakdown")
                if breakdown.isEmpty {
                    emptyState("No cost breakdown yet.")
                } else {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(Array(breakdown.enumerated()), id: \.offset) { index, item in
                            HStack {
                                Text(item.category)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundColor(.white)
                                Spacer()
                                Text(item.amount)
                                    .font(.subheadline)
                                    .foregroundColor(.white.opacity(0.85))
                            }
                            if let notes = item.notes, !notes.isEmpty {
                                Text(notes)
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.7))
                            }

                            if index < breakdown.count - 1 {
                                Divider().background(Color.white.opacity(0.12))
                            }
                        }
                    }
                    .padding(14)
                    .background(Color.white.opacity(0.08))
                    .cornerRadius(14)
                }
            }

            stepsSection(for: plan)

            if let notes = plan.notes, !notes.isEmpty {
                sectionHeader("Notes")
                Text(notes)
                    .font(.body)
                    .foregroundColor(.white.opacity(0.85))
                    .padding(14)
                    .background(Color.white.opacity(0.08))
                    .cornerRadius(14)
            }
        }
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.headline.weight(.semibold))
            .foregroundColor(.white)
    }

    @ViewBuilder
    private func infoRows(for plan: PlanResponse) -> some View {
        if let cost = plan.estimatedCost, !cost.isEmpty {
            infoRow(label: "Estimated cost", value: cost)
        }

        if let duration = plan.estimatedDuration, !duration.isEmpty {
            infoRow(label: "Estimated duration", value: duration)
        }

        if let skill = plan.skillLevel, !skill.isEmpty {
            infoRow(label: "Skill level", value: skill.capitalized)
        }
    }

    private func infoRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.7))
            Spacer()
            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.white)
        }
        .padding(12)
        .background(Color.white.opacity(0.08))
        .cornerRadius(12)
    }

    @ViewBuilder
    private func materialsSection(for materials: [PlanMaterial]) -> some View {
        sectionHeader("Materials")
        if materials.isEmpty {
            emptyState("No materials listed yet.")
        } else {
            VStack(alignment: .leading, spacing: 12) {
                ForEach(Array(materials.enumerated()), id: \.offset) { index, material in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(material.name)
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(.white)
                        if let quantity = material.quantity, !quantity.isEmpty {
                            Text(quantity)
                                .font(.footnote)
                                .foregroundColor(.white.opacity(0.75))
                        }
                        if let notes = material.notes, !notes.isEmpty {
                            Text(notes)
                                .font(.footnote)
                                .foregroundColor(.white.opacity(0.6))
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 6)

                    if index < materials.count - 1 {
                        Divider().background(Color.white.opacity(0.12))
                    }
                }
            }
            .padding(14)
            .background(Color.white.opacity(0.08))
            .cornerRadius(14)
        }
    }

    @ViewBuilder
    private func toolsSection(for tools: [PlanTool]) -> some View {
        sectionHeader("Tools")
        if tools.isEmpty {
            emptyState("No tools required yet.")
        } else {
            VStack(alignment: .leading, spacing: 12) {
                ForEach(Array(tools.enumerated()), id: \.offset) { index, tool in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(tool.name)
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(.white)
                        if let notes = tool.notes, !notes.isEmpty {
                            Text(notes)
                                .font(.footnote)
                                .foregroundColor(.white.opacity(0.65))
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 6)

                    if index < tools.count - 1 {
                        Divider().background(Color.white.opacity(0.12))
                    }
                }
            }
            .padding(14)
            .background(Color.white.opacity(0.08))
            .cornerRadius(14)
        }
    }

    @ViewBuilder
    private func stepsSection(for plan: PlanResponse) -> some View {
        sectionHeader("Steps")
        let orderedPairs = plan.steps.orderedWithOriginalIndices()
        if orderedPairs.isEmpty {
            emptyState("No steps yet.")
        } else {
            let completed = Set(completedSteps)
            VStack(alignment: .leading, spacing: 10) {
                ForEach(Array(orderedPairs.enumerated()), id: \.offset) { entry in
                    let displayIndex = entry.offset
                    let pair = entry.element
                    let isDone = completed.contains(pair.originalIndex)

                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: isDone ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(isDone ? .green : .white.opacity(0.6))
                            .font(.system(size: 18, weight: .medium))
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Step \(displayIndex + 1): \(pair.step.title)")
                                .foregroundColor(.white)
                                .font(.subheadline.weight(.semibold))
                            if let details = pair.step.details, !details.isEmpty {
                                Text(details)
                                    .foregroundColor(.white.opacity(0.8))
                                    .font(.footnote)
                            }
                        }
                    }
                }
            }
            .padding(14)
            .background(Color.white.opacity(0.08))
            .cornerRadius(14)
        }
    }

    private func emptyState(_ message: String) -> some View {
        Text(message)
            .font(.subheadline)
            .foregroundColor(.white.opacity(0.65))
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white.opacity(0.04))
            .cornerRadius(12)
    }
}
