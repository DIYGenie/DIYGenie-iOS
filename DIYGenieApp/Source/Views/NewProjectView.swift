import SwiftUI
import UIKit
#if canImport(RoomPlan)
import RoomPlan
#endif

struct NewProjectView: View {
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isFocused: Bool

    // Form
    @State private var name = ""
    @State private var goal = ""
    @State private var budget = "$$"
    @State private var skill = "beginner"

    // Media / flow
    @State private var showingPicker = false
    @State private var showingCamera = false
    @State private var showingARScanner = false
    @State private var capturedImage: UIImage?
    @State private var projectId: String?
    @State private var createdProject: Project?
    @State private var goToDetails = false

    // UX
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var isLoading = false

    private let api = ProjectsService(
        userId: UserDefaults.standard.string(forKey: "user_id") ?? UUID().uuidString
    )

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {

                // Title + subtitle
                VStack(alignment: .leading, spacing: 6) {
                    Text("New Project")
                        .font(.system(size: 34, weight: .bold))
                        .foregroundColor(.white)
                    Text("Describe your project, add a photo, and (optionally) scan with AR for precise measurements.")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                }
                .padding(.top, 8)

                // Project name
                labeledField_("Project name",
                              text: $name,
                              placeholder: "e.g. Floating Shelves")

                // Goal (multiline with example)
                VStack(alignment: .leading, spacing: 8) {
                    Text("Your goal")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                    ZStack(alignment: .topLeading) {
                        TextEditor(text: $goal)
                            .frame(minHeight: 72)
                            .padding(8)
                            .background(Color.white.opacity(0.08))
                            .cornerRadius(12)
                            .foregroundColor(.white)
                            .focused($isFocused)

                        if goal.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            Text("Example: \"Install 3 floating shelves above the TV and hide the cables\"")
                                .foregroundColor(.white.opacity(0.35))
                                .padding(.horizontal, 14)
                                .padding(.vertical, 12)
                        }
                    }
                }

                // Budget
                VStack(alignment: .leading, spacing: 8) {
                    Text("Budget")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                    segmentedBudget
                    Text("Pick a rough budget to tailor the plan.")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.5))
                }

                // Skill
                VStack(alignment: .leading, spacing: 8) {
                    Text("Skill level")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                    segmentedSkill
                    Text("This helps us size the steps and tool choices.")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.5))
                }

                // AR button ABOVE the image card
                #if canImport(RoomPlan)
                if projectId != nil {
                    Button {
                        showingARScanner = true
                    } label: {
                        HStack {
                            Image(systemName: "viewfinder.circle")
                            Text("Add AR Scan Accuracy")
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.white.opacity(0.12))
                        .cornerRadius(14)
                    }
                } else {
                    // Disabled look before project exists
                    HStack {
                        Image(systemName: "viewfinder.circle")
                        Text("Add AR Scan Accuracy")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.white.opacity(0.06))
                    .cornerRadius(14)
                    .overlay(
                        Text("Create the project first")
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.5))
                            .padding(.top, 4),
                        alignment: .bottom
                    )
                }
                #endif

                // Image card (small)
                VStack(alignment: .leading, spacing: 10) {
                    Text("Room photo")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)

                    if let img = capturedImage {
                        HStack(spacing: 12) {
                            Image(uiImage: img)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 110, height: 110)
                                .clipped()
                                .cornerRadius(12)

                            VStack(alignment: .leading, spacing: 8) {
                                Text("Photo attached")
                                    .foregroundColor(.white)
                                    .font(.subheadline).bold()
                                Text("Use AR or take another photo for measurement accuracy.")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.6))
                            }
                            Spacer()
                        }
                        .padding(12)
                        .background(Color.white.opacity(0.06))
                        .cornerRadius(14)
                    } else {
                        Button {
                            showingPicker = true
                        } label: {
                            HStack {
                                Image(systemName: "photo.on.rectangle.angled")
                                Text("Add a room photo")
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.white.opacity(0.08))
                            .cornerRadius(14)
                        }
                    }

                    // Take photo (camera)
                    Button {
                        showingCamera = true
                    } label: {
                        HStack {
                            Image(systemName: "camera.viewfinder")
                            Text("Take Photo for Measurements")
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.white.opacity(0.12))
                        .cornerRadius(14)
                    }
                }

                // Primary / secondary CTAs
                VStack(spacing: 12) {
                    Button {
                        Task { await createProjectAndUpload(generatePreview: true) }
                    } label: {
                        Text("Generate AI Plan + Preview")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(LinearGradient(colors: [Color(red: 0.48, green: 0.35, blue: 1.0),
                                                               Color(red: 0.65, green: 0.45, blue: 1.0)],
                                                       startPoint: .leading, endPoint: .trailing))
                            .cornerRadius(16)
                            .foregroundColor(.white)
                    }
                    .disabled(isLoading)

                    Button {
                        Task { await createProjectAndUpload(generatePreview: false) }
                    } label: {
                        Text("Create Plan Only (no preview)")
                            .font(.subheadline.weight(.semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.white.opacity(0.08))
                            .cornerRadius(16)
                            .foregroundColor(.white)
                    }
                    .disabled(isLoading)
                }
                .padding(.top, 8)

                if isLoading {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(.white)
                        .frame(maxWidth: .infinity)
                }

                NavigationLink(isActive: $goToDetails) {
                    if let p = createdProject {
                        ProjectDetailsView(project: p)
                    } else {
                        EmptyView()
                    }
                } label: { EmptyView() }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(Color.black.opacity(0.9).ignoresSafeArea())
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Back") { dismiss() }
            }
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") { isFocused = false }
            }
        }
        // Pickers
        .sheet(isPresented: $showingPicker) {
            ImagePicker(sourceType: .photoLibrary) { img in
                capturedImage = img
            }
        }
        .sheet(isPresented: $showingCamera) {
            ImagePicker(sourceType: .camera) { img in
                capturedImage = img
            }
        }
        // AR scanner sheet
        #if canImport(RoomPlan)
        .sheet(isPresented: $showingARScanner) {
            if let id = projectId {
                ARRoomPlanSheet(projectId: id) { _ in
                    // usdz exported & handled by ARRoomPlanSheet; nothing else needed here
                }
            } else {
                // safety: shouldn’t appear (button disabled), but keep empty view
                Text("Create the project first.")
                    .padding()
            }
        }
        #endif
        .alert("Error", isPresented: $showAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
    }

    // MARK: - Segmented controls

    private var segmentedBudget: some View {
        HStack(spacing: 10) {
            segment("$", value: "$")
            segment("$$", value: "$$")
            segment("$$$", value: "$$$")
        }
    }

    private func segment(_ title: String, value: String) -> some View {
        Button {
            budget = value
        } label: {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(budget == value ? Color.white.opacity(0.20) : Color.white.opacity(0.08))
                .cornerRadius(12)
        }
    }

    private var segmentedSkill: some View {
        HStack(spacing: 10) {
            skillSegment("Beginner", value: "beginner")
            skillSegment("Intermediate", value: "intermediate")
            skillSegment("Advanced", value: "advanced")
        }
    }

    private func skillSegment(_ title: String, value: String) -> some View {
        Button {
            skill = value
        } label: {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(skill == value ? Color.white.opacity(0.20) : Color.white.opacity(0.08))
                .cornerRadius(12)
        }
    }

    // MARK: - Actions

    private func createProjectAndUpload(generatePreview: Bool) async {
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else {
            alert("Please enter a project name.")
            return
        }
        guard let image = capturedImage else {
            alert("Please add a room photo (or take one).")
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            // 1) Create project
            let created = try await api.createProject(
                name: name,
                goal: goal,
                budget: budget,
                skillLevel: skill
            )
            self.projectId = created.id

            // 2) Upload image
            try await api.uploadImage(projectId: created.id, image: image)

            // 3) (Optional) request preview — intentionally NOT calling a missing method

            // 4) Navigate
            self.createdProject = created
            self.goToDetails = true

        } catch {
            alert("Failed to create project: \(error.localizedDescription)")
        }
    }

    // MARK: - Helpers

    private func alert(_ msg: String) {
        alertMessage = msg
        showAlert = true
    }

    private func labeledField_( _ title: String,
                               text: Binding<String>,
                               placeholder: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
            TextField(placeholder, text: text)
                .textInputAutocapitalization(.sentences)
                .padding(12)
                .background(Color.white.opacity(0.08))
                .cornerRadius(12)
                .foregroundColor(.white)
        }
    }
}

