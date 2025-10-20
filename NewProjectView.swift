import SwiftUI

struct NewProjectView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var name: String = ""
    @State private var goal: String = ""
    @State private var budget: Double = 1.0
    @State private var skillLevel: String = "beginner"
    @State private var isWorking: Bool = false
    @State private var errorMessage: String? = nil

    let onCreated: (Project) -> Void

    private let userId = UUID(uuidString: "99198c4b-8470-49e2-895c-75593c5aa181")!
    private let skillLevels = ["beginner", "intermediate", "advanced"]

    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    TextField("Name", text: $name)
                    TextField("Goal", text: $goal)
                }
                Section("Budget") {
                    Slider(value: $budget, in: 0...10000, step: 100) {
                        Text("Budget")
                    }
                    Text("$\(Int(budget))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Section("Skill Level") {
                    Picker("Skill", selection: $skillLevel) {
                        ForEach(skillLevels, id: \.self) { level in
                            Text(level.capitalized).tag(level)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                if let errorMessage {
                    Section {
                        Text(errorMessage).foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("New Project")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Create") { Task { await create() } }
                        .disabled(isWorking || name.isEmpty || goal.isEmpty)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .disabled(isWorking)
                }
            }
            .overlay {
                if isWorking { ProgressView("Working…") }
            }
        }
    }

    @MainActor
    private func create() async {
        guard !isWorking else { return }
        isWorking = true
        defer { isWorking = false }
        do {
            let p = try await ProjectsService.shared.create(
                name: name,
                goal: goal,
                budget: budget,
                skill: skillLevel,
                userId: userId.uuidString
            )
            _ = try await ProjectsService.shared.attachPhoto(
                projectId: p.idAsUUID(),
                url: URL(string: "https://example.com/photo.jpg")!
            )
            let status = try await ProjectsService.shared.requestPreview(projectId: p.idAsUUID())

            print("Preview status: \(status.status)")
            onCreated(p)
            dismiss()
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }
}

#Preview {
    NewProjectView { _ in }
}
