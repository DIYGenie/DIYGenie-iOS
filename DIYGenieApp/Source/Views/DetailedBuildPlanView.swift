//
//  DetailedBuildPlanView.swift
//  DIYGenieApp
//

import SwiftUI

/// A view that presents a comprehensive DIY build plan.
/// Displayed as a set of organized sections showing recommended tools,
/// materials, and step-by-step instructions. If the plan is nil, it shows a placeholder.
struct DetailedBuildPlanView: View {
    let plan: PlanResponse?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("Detailed Build Plan")
                    .font(.largeTitle)
                    .bold()

                if let plan = plan {
                    // MARK: - Tools Section
                    if let tools = plan.tools, !tools.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Recommended Tools")
                                .font(.headline)
                            ForEach(tools, id: \.self) { tool in
                                Text("• \(tool)")
                            }
                        }
                    }

                    // MARK: - Materials Section
                    if let materials = plan.materials, !materials.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Materials Needed")
                                .font(.headline)
                            ForEach(materials, id: \.self) { material in
                                Text("• \(material)")
                            }
                        }
                    }

                    // MARK: - Steps Section
                    if let steps = plan.steps, !steps.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Step-by-Step Instructions")
                                .font(.headline)
                            ForEach(steps.indices, id: \.self) { i in
                                Text("\(i + 1). \(steps[i])")
                            }
                        }
                    }

                    // MARK: - Cost Section
                    if let cost = plan.estimatedCost {
                        Text("Estimated Cost: $\(cost, specifier: "%.2f")")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding(.top, 8)
                    }

                } else {
                    Text("Plan data not available.")
                        .foregroundColor(.secondary)
                        .padding(.top, 16)
                }
            }
            .padding(.horizontal)
        }
    }
}
