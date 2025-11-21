//
//  ProjectDetailsView.swift
//  DIYGenieApp
//

import SwiftUI
import UIKit

struct ProjectDetailsView: View {
    let project: Project

    @State private var selectedImage: ImageKind = .preview
    @State private var isShowingShareSheet = false
    @State private var shareItems: [Any] = []
    @State private var showAllSteps = false

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

    private var availableImageKinds: [ImageKind] {
        var kinds: [ImageKind] = []
        if previewOrPhotoURL != nil { kinds.append(.preview) }
        if originalPhotoURL != nil { kinds.append(.original) }
        return kinds
    }

    private var toolsList: [PlanTool] {
        project.planJSON?.tools ?? []
    }

    private var planSteps: [PlanStep] {
        project.planJSON?.steps ?? []
    }

    private var completedSteps: Set<Int> {
        Set(project.completedSteps ?? [])
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
                VStack(spacing: 22) {
                    headerSection
                    toolsSection
                    progressCard
                    mediaSection
                        .padding(.top, 6)
                    planSummarySection
                        .padding(.top, 6)

                    NavigationLink {
                        BuildPlanView(plan: project.planJSON)
                    } label: {
                        Text("View Detailed Build Plan")
                            .font(.headline.weight(.semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
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

                    sharePlanButton

                    Spacer(minLength: 32)
                }
                .padding(18)
            }
        }
        .onAppear {
            if let plan = project.planJson {
                print("[ProjectDetailsView] Plan summary: \(plan.summary ?? "<no summary>")")
            }
            if !availableImageKinds.contains(selectedImage), let first = availableImageKinds.first {
                selectedImage = first
            }
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(project.name)
                        .font(.largeTitle.bold())
                        .foregroundColor(.white)
                        .multilineTextAlignment(.leading)

                    if let status = project.status, !status.isEmpty {
                        Text(status.capitalized)
                            .font(.footnote.weight(.semibold))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color.white.opacity(0.12))
                            .cornerRadius(10)
                            .foregroundColor(.white.opacity(0.9))
                    }
                }
                Spacer()
            }

            if let summary = project.planJSON?.summary ?? project.goal, !summary.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Text(summary)
                    .foregroundColor(Color.white.opacity(0.85))
                    .font(.body)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var toolsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Required Tools")

            VStack(alignment: .leading, spacing: 10) {
                if toolsList.isEmpty {
                    Text("Tools will appear once the plan is generated.")
                        .foregroundColor(.white.opacity(0.7))
                } else {
                    ForEach(toolsList, id: \.id) { tool in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(tool.name)
                                .foregroundColor(.white)
                            if let notes = tool.notes, !notes.isEmpty {
                                Text(notes)
                                    .font(.footnote)
                                    .foregroundColor(.white.opacity(0.7))
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        Divider().background(Color.white.opacity(0.12))
                            .opacity(tool == toolsList.last ? 0 : 1)
                    }
                }
            }
            .padding(14)
            .background(Color.white.opacity(0.06))
            .cornerRadius(14)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var progressCard: some View {
        let totalSteps = planSteps.count
        let completed = completedSteps
        let progress = totalSteps == 0 ? 0 : Double(completed.count) / Double(totalSteps)
        return VStack(alignment: .leading, spacing: 14) {
            sectionHeader("Build Progress")

            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("\(Int(progress * 100))% complete")
                        .font(.headline.weight(.semibold))
                        .foregroundColor(.white)
                    Spacer()
                    Text("\(completed.count)/\(max(totalSteps, 1)) steps")
                        .foregroundColor(.white.opacity(0.75))
                        .font(.subheadline)
                }

                ProgressView(value: progress)
                    .tint(Color("Accent"))

                VStack(alignment: .leading, spacing: 14) {
                    let shouldCollapse = planSteps.count > 4
                    let stepsToShow = shouldCollapse && !showAllSteps ? Array(planSteps.prefix(4)) : planSteps

                    ForEach(Array(stepsToShow.enumerated()), id: \.offset) { index, step in
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: completed.contains(step.id) ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(completed.contains(step.id) ? Color.green : Color.white.opacity(0.7))
                                .font(.system(size: 18, weight: .semibold))
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Step \(index + 1)")
                                    .font(.caption.weight(.semibold))
                                    .foregroundColor(.white.opacity(0.8))
                                Text(step.title)
                                    .foregroundColor(.white)
                                    .font(.callout.weight(.semibold))
                                if let details = step.details, !details.isEmpty {
                                    Text(details)
                                        .foregroundColor(.white.opacity(0.75))
                                        .font(.caption)
                                        .lineSpacing(3)
                                }
                            }
                        }
                        if index < stepsToShow.count - 1 {
                            Divider().background(Color.white.opacity(0.15))
                        }
                    }
                    if planSteps.isEmpty {
                        Text("Steps will appear after your plan is ready.")
                            .foregroundColor(.white.opacity(0.7))
                    } else if planSteps.count > 4 {
                        Button(action: { showAllSteps.toggle() }) {
                            Text(showAllSteps ? "Show Fewer Steps" : "Show All Steps")
                                .font(.footnote.weight(.semibold))
                                .foregroundColor(Color("Accent"))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(Color.white.opacity(0.06))
                                .cornerRadius(10)
                        }
                    }
                }

                HStack(spacing: 12) {
                    Button(action: {}) {
                        Text("Continue Building")
                            .font(.headline.weight(.semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color("Accent"))
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }

                    Button(action: copySteps) {
                        Text("Copy Steps")
                            .font(.headline.weight(.semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.white.opacity(0.1))
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    .disabled(planSteps.isEmpty)
                    .opacity(planSteps.isEmpty ? 0.6 : 1)
                }
            }
            .padding(16)
            .background(Color.white.opacity(0.06))
            .cornerRadius(16)
        }
    }

    private var mediaSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader("Project Images")

            if availableImageKinds.count > 1 {
                Picker("Image", selection: $selectedImage) {
                    ForEach(availableImageKinds, id: \.self) { kind in
                        Text(kind.title).tag(kind)
                    }
                }
                .pickerStyle(.segmented)
            }

            if let imageURL = imageURL(for: selectedImage) ?? previewOrPhotoURL ?? originalPhotoURL {
                ZStack(alignment: .topTrailing) {
                    mediaCard(title: selectedImage.title, url: imageURL)

                    if selectedImage == .preview, previewOrPhotoURL != nil {
                        Button(action: { shareImage(url: imageURL) }) {
                            Image(systemName: "arrow.down.circle.fill")
                                .font(.title3)
                                .foregroundColor(.white)
                                .padding(8)
                                .background(Color.black.opacity(0.35))
                                .clipShape(Circle())
                                .padding(10)
                        }
                    }
                }

                if isUsingPreviewFallback {
                    Text("Preview not available; showing project photo instead.")
                        .font(.footnote)
                        .foregroundColor(.yellow.opacity(0.9))
                }
            } else {
                Text("No images available")
                    .font(.footnote)
                    .foregroundColor(.yellow.opacity(0.9))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var planSummarySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Plan Overview")

            if let plan = project.planJSON {
                VStack(alignment: .leading, spacing: 12) {
                    if estimatedCostText != nil || durationText != nil || skillText != nil {
                        VStack(spacing: 10) {
                            if let cost = estimatedCostText {
                                infoRow(title: "Estimated Cost", value: cost)
                            }
                            if let duration = durationText {
                                infoRow(title: "Duration", value: duration)
                            }
                            if let skill = skillText {
                                infoRow(title: "Skill Level", value: skill)
                            }
                        }
                        .padding(14)
                        .background(Color.white.opacity(0.06))
                        .cornerRadius(14)
                    }

                    if let summary = plan.summary, !summary.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Summary")
                                .font(.headline)
                                .foregroundColor(.white)
                            Text(summary)
                                .foregroundColor(.white.opacity(0.85))
                                .font(.body)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(14)
                        .background(Color.white.opacity(0.06))
                        .cornerRadius(14)
                    }

                    let planMaterialNames: [String]? = {
                        let mapped = plan.materials.map { $0.name }
                        return mapped.isEmpty ? nil : mapped
                    }()

                    if let materials = project.materials ?? planMaterialNames, !materials.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
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
                }
            } else {
                Text("Plan is generating. Check back in a moment.")
                    .foregroundColor(.white.opacity(0.75))
                    .font(.body)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var sharePlanButton: some View {
        Button(action: sharePlan) {
            Text("Share Plan")
                .font(.headline.weight(.semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 18)
                        .fill(Color.white.opacity(0.12))
                )
        }
        .sheet(isPresented: $isShowingShareSheet) {
            ShareSheet(activityItems: shareItems)
        }
    }

    private func mediaCard(title: String, url: URL) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundColor(.white)

            ProjectMediaView(url: url)
        }
    }

    private func copySteps() {
        guard !planSteps.isEmpty else { return }
        let stepsText = planSteps.enumerated().map { index, step in
            "Step \(index + 1): \(step.title)\n\(step.details ?? "")"
        }.joined(separator: "\n\n")
        shareItems = [stepsText]
        isShowingShareSheet = true
    }

    private func sharePlan() {
        var items: [Any] = []
        if let summary = project.planJSON?.summary {
            items.append(summary)
        } else {
            items.append("DIY plan for \(project.name)")
        }
        shareItems = items
        isShowingShareSheet = true
    }

    private func shareImage(url: URL) {
        shareItems = [url]
        isShowingShareSheet = true
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.title3.weight(.semibold))
            .foregroundColor(.white)
    }

    private func infoRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(.footnote.weight(.semibold))
                .foregroundColor(.white.opacity(0.75))
            Spacer()
            Text(value)
                .font(.callout.weight(.semibold))
                .foregroundColor(.white)
        }
    }

    private func imageURL(for kind: ImageKind) -> URL? {
        switch kind {
        case .preview:
            return previewOrPhotoURL
        case .original:
            return originalPhotoURL
        }
    }
}

private enum ImageKind: Hashable {
    case preview
    case original

    var title: String {
        switch self {
        case .preview: return "Preview"
        case .original: return "Original"
        }
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
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.35), radius: 8, x: 0, y: 4)
    }

    private var placeholder: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.06))
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
