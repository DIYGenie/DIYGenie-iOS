import SwiftUI

/// A view that presents a comprehensive DIY build plan.
///
/// Displayed as a set of organized sections, the plan highlights recommended tools,
/// materials, and step‑by‑step instructions. This view assumes the plan has already
/// been fetched from the backend and passed in as a parameter.
struct DetailedBuildPlanView: View {
    /// The complete plan for a project.  If nil, the view will show a placeholder message.
    let plan: PlanResponse?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("Detailed Build Plan")
                    .font(.largeTitle)
                    .bold()

                if let plan = plan {
                    // Tools section
                    if !plan.tools.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Recommended Tools")
                                .font(.headline)
                            ForEach(plan.tools, id: \ .self) { tool in
                                Text("• \(tool)")
                            }
                        }
                    }

                    // Materials section
                    if !plan.materials.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Materials")
                                .font(.headline)
                            ForEach(plan.materials, id: \ .self) { material in
                                Text("• \(material)")
                            }
                        }
                    }

                    // Step‑by‑step instructions
                    if !plan.steps.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Step‑by‑Step Instructions")
                                .font(.headline)
                            ForEach(Array(plan.steps.enumerated()), id: \ .offset) { index, step in
                                HStack(alignment: .top) {
                                    Text("\(index + 1).")
                                        .fontWeight(.bold)
                                    Text(step)
                                }
                                .padding(.bottom, 4)
                            }
                        }
                    }
                } else {
                    // Placeholder when no plan is available
                    Text("A detailed plan will appear here once it has been generated.")
                        .foregroundColor(.secondary)
                }

                Spacer(minLength: 20)
            }
            .padding()
        }
        .navigationTitle("Detailed Plan")
        .navigationBarTitleDisplayMode(.inline)
    }
}

