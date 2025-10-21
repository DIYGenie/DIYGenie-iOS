import SwiftUI

struct NewProjectView: View {
    @Environment(\.dismiss) private var dismiss

    // Form state
    @State private var name: String = ""
    @State private var goal: String = ""
    @State private var budget: Double = 1500
    @State private var skillLevel: String = "beginner"
    private let skillLevels = ["beginner", "intermediate", "advanced"]

    // Progress + errors
    @State private var isWorking = false
    @State private var errorMessage: String?

    // AR measure
    @State private var showMeasure = false
    @State private var capturedSummary: RoomPlanSummary?

    let onCreated: (Project) -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    TextField("Name (min 10 chars)", text: $name)
                        .textInputAutocapitalization(.words)
                        .autocorrectionDisabled()
                    TextField("Goal (optional)", text: $goal)
                        .textInputAutocapitalization(.sentences)
                }

                Section("Budget") {
                    Slider(value: $budget, in: 0...10000, step: 100) { Text("Budget") }
                    HStack {
                        Text("Approx: $\(Int(budget))").foregroundStyle(.secondary)
                        Spacer()
                        Text("Tier: \(budgetTier)").font(.caption).foregroundStyle(.secondary)
                    }
                }

                Section("Skill Level") {
                    Picker("Skill", selection: $skillLevel) {
                        ForEach(skillLevels, id: \.self) { Text($0.capitalized).tag($0) }
                    }.pickerStyle(.segmented)
                }

                if let s = capturedSummary {
                    Section("Measured (AR)") {
                        VStack(alignment: .leading, spacing: 6) {
                            if let area = s.totalArea {
                                Text("Area ≈ \(String(format: "%.1f", area)) m²")
                            }
                            if let walls = s.wallCount {
                                Text("Walls: \(walls)")
                            }
                            if let openings = s.openingsCount {
                                Text("Openings: \(openings)")
                            }
                        }
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    }
                }

                if let errorMessage {
                    Section { Text(errorMessage).foregroundStyle(.red) }
                }
            }
            .navigationTitle("New Project")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showMeasure = true
                    } label: {
                        Label("Measure with AR", systemImage: "arkit")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Create") { Task { await create() } }
                        .disabled(isWorking || name.count < 10)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }.disabled(isWorking)
                }
            }
            .overlay {
                if isWorking {
                    ProgressView("Working…").frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .sheet(isPresented: $showMeasure) {
#if targetEnvironment(simulator)
                // Simulator has no camera/AR — close immediately or add manual inputs here if desired.
                VStack(spacing: 12) {
                    Image(systemName: "arkit").font(.largeTitle)
                    Text("AR not available in Simulator.").foregroundStyle(.secondary)
                    Button("Close") { showMeasure = false }
                        .buttonStyle(.borderedProminent)
                }.padding()
#else
                if #available(iOS 16.0, *), RoomPlanAvailability.isSupported {
                    RoomPlanView { summary in
                        capturedSummary = summary
                        showMeasure = false
                    }
                } else {
                    MeasureView { summary in
                        capturedSummary = summary
                        showMeasure = false
                    }
                }
#endif
            }
        }
    }

    // MARK: - Create flow
    @MainActor
    private func create() async {
        guard !isWorking else { return }
        isWorking = true
        errorMessage = nil
        defer { isWorking = false }

        do {
            let service = ProjectsService()
            let userId = UserSession.shared.userId

            // Merge AR summary into goal so backend receives it without schema changes.
            let mergedGoal = mergedGoalText(userGoal: goal, summary: capturedSummary)

            // Create (returns lightweight Project)
            let created = try await service.create(
                userId: userId,
                name: name,
                goal: mergedGoal,
                budget: budgetTier
            )

        
            onCreated(created)
            dismiss()
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }

    // MARK: - Helpers
    private var budgetTier: String {
        switch budget {
        case ..<1000: return "$"
        case 1000..<5000: return "$$"
        default: return "$$$"
        }
    }

    /// Append a short AR summary to the user's goal for backend visibility.
    private func mergedGoalText(userGoal: String, summary: RoomPlanSummary?) -> String? {
        guard let summary else {
            return userGoal.isEmpty ? nil : userGoal
        }
        var parts: [String] = []
        if let area = summary.totalArea { parts.append("~\(String(format: "%.1f", area)) m²") }
        if let walls = summary.wallCount { parts.append("\(walls) walls") }
        if let opens = summary.openingsCount { parts.append("\(opens) openings") }
        let arLine = parts.isEmpty ? "Measured with AR" : "Measured: " + parts.joined(separator: ", ")
        if userGoal.isEmpty { return arLine }
        return userGoal + " — " + arLine
    }
}

#Preview { NewProjectView { _ in } }
// ✅ Ready to Build
