// NewProjectView.swift
import SwiftUI
import PhotosUI
import AVFoundation

func ensureCameraPermission() async -> Bool {
    let status = AVCaptureDevice.authorizationStatus(for: .video)
    switch status {
    case .authorized:
        return true
    case .notDetermined:
        return await AVCaptureDevice.requestAccess(for: .video)
    default:
        return false
    }
}
extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
struct NewProjectView: View {
    @Environment(\.dismiss) private var dismiss

    // Form state
    @State private var name = ""
    @State private var goal = ""
    @State private var budgetTier: Budget = .two
    @State private var skill: Skill = .intermediate

    // Optional media
    @State private var pickedPhoto: PhotosPickerItem?
    @State private var pickedPhotoData: Data?

    // Optional RoomPlan capture
    @State private var showMeasure = false
    @State private var capturedSummary: RoomPlanSummary?

    // UI state
    @State private var isWorking = false
    @State private var errorMessage: String?

    /// Called by the list screen after creation so it can insert the new item.
    let onCreated: (Project) -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section("Project Title") {
                    TextField("e.g. Floating shelves", text: $name)
                        .textInputAutocapitalization(.words)
                }

                Section("Project Description") {
                    TextField("What do you want to achieve?", text: $goal, axis: .vertical)
                        .lineLimit(3...6)
                }

                Section("Budget") {
                    Picker("Budget", selection: $budgetTier) {
                        ForEach(Budget.allCases) { b in
                            Text(b.label).tag(b)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("Skill Level") {
                    Picker("Skill", selection: $skill) {
                        ForEach(Skill.allCases) { s in
                            Text(s.label).tag(s)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("Add a room photo (optional)") {
                    PhotosPicker("Choose Photo", selection: $pickedPhoto, matching: .images)
                        .onChange(of: pickedPhoto) { _ in
                            Task { pickedPhotoData = try? await pickedPhoto?.loadTransferable(type: Data.self) }
                        }
                    
                    Button("Scan Room") {
                        hideKeyboard()
                        Task {
                            let ok = await ensureCameraPermission()
                            if ok {
                                showMeasure = true
                            } else {
                                errorMessage = "Camera access is required for AR scanning. Enable it in Settings > DIYGenie > Camera."
                            }
                        }
                    }
                    
                
                        Label("Scan room (RoomPlan / fallback)", systemImage: "arkit")
                    }
                }

                if let capturedSummary {
                    Section("Scan summary") {
                        if let a = capturedSummary.totalArea {
                            Text("Area (approx): \(a, specifier: "%.2f") m²")
                        }
                        Text("Walls: \(capturedSummary.wallCount ?? 0)")
                        Text("Openings: \(capturedSummary.openingsCount ?? 0)")
                    }
                }

                if let errorMessage {
                    Section { Text(errorMessage).foregroundStyle(.red) }
                }
            }
            .navigationTitle("New Project")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }.disabled(isWorking)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Create") { Task { await create() } }
                        .disabled(isWorking || name.isEmpty || goal.isEmpty)
                }
            }
            .sheet(isPresented: $showMeasure) {
                RoomPlanView { summary in
                    capturedSummary = summary
                    showMeasure = false
                }
            }
            .overlay {
                if isWorking { ProgressView("Working…") }
            }
        }
    }


// MARK: - Actions
extension NewProjectView {
    @MainActor
    private func create() async {
        guard !isWorking else { return }
        isWorking = true
        defer { isWorking = false }

        do {
            let service = ProjectsService()
            let userId = UserSession.shared.userId

            guard let userUUID = UUID(uuidString: userId) else {
                throw SimpleError("Invalid user id")
            }

            let body = CreateProjectBody(
                name: name,
                goal: goal,
                user_id: userUUID,
                client: "ios",
                budget: budgetTier.numeric,
                skill_level: skill.rawValue
            )

            let created: CreateProjectDTO = try await service.create(userId: userId, body: body)

            if let data = pickedPhotoData {
                // Best-effort photo upload and preview; errors are non-fatal to project creation
                try? await service.uploadPhoto(
                    userId: userId,
                    projectId: created.id.uuidString,
                    jpegData: data
                )
                try? await service.preview(
                    userId: userId,
                    projectId: created.id.uuidString
                )
            }

            // Map DTO to UI model
            let project = Project(
                id: created.id.uuidString,
                name: created.name,
                goal: created.goal,
                status: created.status
            )

            onCreated(project)
            dismiss()
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }
}

// MARK: - Helpers


private struct SimpleError: LocalizedError {
    let errorDescription: String?
    init(_ s: String) { errorDescription = s }
}

private enum Budget: Double, CaseIterable, Identifiable {
    case one = 1, two = 2, three = 3
    var id: Self { self }
    var label: String {
        switch self { case .one: return "$"; case .two: return "$$"; case .three: return "$$$" }
    }
    var numeric: Double { rawValue }
}

private enum Skill: String, CaseIterable, Identifiable {
    case beginner, intermediate, advanced
    var id: Self { self }
    var label: String {
        switch self {
        case .beginner: return "Beginner"
        case .intermediate: return "Intermediate"
        case .advanced: return "Advanced"
        }
    }
}
