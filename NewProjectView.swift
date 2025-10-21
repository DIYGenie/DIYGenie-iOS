import SwiftUI
#if canImport(RoomPlan)
import RoomPlan
#endif

struct NewProjectView: View {
    @Environment(\.dismiss) private var dismiss

    // Form state
    @State private var showCreate = false
    @State private var name: String = ""
    @State private var goal: String = ""
    @State private var budget: Double = 1500         // dollars; we map to $, $$, $$$
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
                    Slider(value: $budget, in: 0...10000, step: 100) {
                        Text("Budget")
                    }
                    HStack {
                        Text("Approx: $\(Int(budget))")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("Tier: \(budgetTier)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Skill Level") {
                    Picker("Skill", selection: $skillLevel) {
                        ForEach(skillLevels, id: \.self) { level in
                            Text(level.capitalized).tag(level)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                if isRoomPlanSupported {
                    Section("AR Measure") {
                        Button {
                            showMeasure = true
                        } label: {
                            Label("Measure Room", systemImage: "ruler")
                        }
                    }
                }

                if let capturedSummary {
                    Section("Measured (AR)") {
                        VStack(alignment: .leading, spacing: 6) {
                            if let area = capturedSummary.totalArea {
                                Text("Area ≈ \(String(format: "%.1f", area)) m²")
                            }
                            if let walls = capturedSummary.wallCount {
                                Text("Walls: \(walls)")
                            }
                            if let openings = capturedSummary.openingsCount {
                                Text("Openings: \(openings)")
                            }
                            if !capturedSummary.segments.isEmpty {
                                Text("Segments: \(capturedSummary.segments.count)")
                            }
                        }
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    }
                }

                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("New Project")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        if name.trimmingCharacters(in: .whitespacesAndNewlines).count < 10 {
                            errorMessage = "Name must be at least 10 characters."
                        } else {
                            showCreate = true
                        }
                    } label: { Image(systemName: "plus") }
                }
            }
            .overlay {
                if isWorking {
                    ProgressView("Working…")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .sheet(isPresented: $showCreate) {
                NavigationStack {
                    VStack(spacing: 16) {
                        Text("Create this project?")
                            .font(.headline)
                        Button("Create") {
                            Task { await create() }
                        }
                        .buttonStyle(.borderedProminent)
                        Button("Cancel") { showCreate = false }
                    }
                    .padding()
                    .navigationTitle("Confirm")
                    .navigationBarTitleDisplayMode(.inline)
                }
            }
            .sheet(isPresented: $showMeasure) {
                MeasureView { summary in
                    capturedSummary = summary
                    showMeasure = false
                }
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
            let userId = UserSession.shared.userId                 // query param per manifest
            // Server expects: name (required, min 10), optional goal, optional client.budget
            let created = try await service.create(
                userId: userId,
                name: name,
                goal: goal.isEmpty ? nil : goal,
                budget: budgetTier
            )
            // Optionally queue preview here if you want:
            // let _ = try await service.preview(userId: userId, projectId: created.id.uuidString)

            onCreated(created)
            dismiss()
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }

    // MARK: - Helpers

    /// Map approximate dollars to server's "$|$$|$$$" tiers.
    private var budgetTier: String {
        switch budget {
        case ..<1000: return "$"
        case 1000..<5000: return "$$"
        default: return "$$$"
        }
    }

    /// Whether RoomPlan is available and supported on this device.
    private var isRoomPlanSupported: Bool {
        #if canImport(RoomPlan)
        if #available(iOS 16.0, *) {
            return RoomCaptureSession.isSupported
        } else {
            return false
        }
        #else
        return false
        #endif
    }
}

#Preview {
    NewProjectView { _ in }
}
// ✅ Ready to Build

