//
//  BuildPlanView.swift
//  DIYGenieApp
//

import SwiftUI

struct BuildPlanView: View {
    let plan: PlanResponse?

    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [Color("BGStart"), Color("BGEnd")]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView {
                if let plan {
                    VStack(alignment: .leading, spacing: 20) {
                        header(plan)
                        metadata(plan)
                        materials(plan.materials)
                        steps(plan)
                        if let notes = plan.notes, !notes.isEmpty {
                            notesSection(notes)
                        }
                    }
                    .padding(18)
                } else {
                    VStack(spacing: 12) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        Text("Loading plan…")
                            .foregroundColor(.white.opacity(0.85))
                    }
                }
            }
        }
        .navigationTitle("Build Plan")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func header(_ plan: PlanResponse) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("AI Build Plan")
                .font(.largeTitle.bold())
                .foregroundColor(.white)
            if let summary = plan.summary, !summary.isEmpty {
                Text(summary)
                    .foregroundColor(.white.opacity(0.85))
                    .font(.body)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func metadata(_ plan: PlanResponse) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            if let cost = plan.estimatedCost, !cost.isEmpty {
                infoRow(title: "Estimated Cost", value: cost)
            }
            if let duration = plan.estimatedDuration, !duration.isEmpty {
                infoRow(title: "Timeline", value: duration)
            }
            if let skill = plan.skillLevel, !skill.isEmpty {
                infoRow(title: "Skill Level", value: skill.capitalized)
            }
        }
        .padding(14)
        .background(Color.white.opacity(0.08))
        .cornerRadius(14)
    }

    private func materials(_ materials: [PlanMaterial]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Materials List")
                .font(.headline.weight(.semibold))
                .foregroundColor(.white)

            if materials.isEmpty {
                Text("No materials listed yet.")
                    .foregroundColor(.white.opacity(0.7))
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
                        if index < materials.count - 1 {
                            Divider().background(Color.white.opacity(0.12))
                        }
                    }
                }
                .padding(14)
                .background(Color.white.opacity(0.06))
                .cornerRadius(14)
            }
        }
    }

    private func steps(_ plan: PlanResponse) -> some View {
        let ordered = plan.steps.orderedWithOriginalIndices()
        return VStack(alignment: .leading, spacing: 10) {
            Text("Step-by-Step Instructions")
                .font(.headline.weight(.semibold))
                .foregroundColor(.white)

            if ordered.isEmpty {
                Text("No steps available.")
                    .foregroundColor(.white.opacity(0.7))
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(Array(ordered.enumerated()), id: \.offset) { entry in
                        let index = entry.offset + 1
                        let step = entry.element.step
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Step \(index): \(step.title)")
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(.white)
                            if let details = step.details, !details.isEmpty {
                                Text(details)
                                    .foregroundColor(.white.opacity(0.85))
                            }
                            if let estimate = step.estimatedTime, !estimate.isEmpty {
                                Text("Estimated time: \(estimate)")
                                    .font(.footnote)
                                    .foregroundColor(.white.opacity(0.7))
                            }
                        }
                        if entry.offset < ordered.count - 1 {
                            Divider().background(Color.white.opacity(0.12))
                        }
                    }
                }
                .padding(14)
                .background(Color.white.opacity(0.06))
                .cornerRadius(14)
            }
        }
    }

    private func notesSection(_ notes: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Notes")
                .font(.headline.weight(.semibold))
                .foregroundColor(.white)
            Text(notes)
                .foregroundColor(.white.opacity(0.85))
        }
        .padding(14)
        .background(Color.white.opacity(0.06))
        .cornerRadius(14)
    }

    private func infoRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .foregroundColor(.white.opacity(0.7))
                .font(.subheadline)
            Spacer()
            Text(value)
                .foregroundColor(.white)
                .font(.subheadline.weight(.semibold))
        }
    }
}
