import SwiftUI
import PhotosUI

/// A screen for creating a new DIY Genie project.
///
/// This view lets the user enter a project name and description, pick a budget and skill level,
/// optionally scan the room or upload a photo, and then choose to generate an AI plan with a
/// visual preview or just create a plan without a preview. After submission the user is
/// navigated directly to the details page for the created project.
struct NewProjectView: View {
    @State private var title: String = ""
    @State private var goal: String = ""
    @State private var budget: String = "$"
    @State private var skillLevel: String = "Beginner"
    @State private var isSubmitting: Bool = false
    @State private var createdProject: Project?
    @State private var navigateToDetails: Bool = false
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImageData: Data?

    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""

    // Replace this UUID with the appropriate user identifier used by your backend.
    private let projectsService = ProjectsService(userId: "99198c4b-8470-49e2-895c-75593c5aa181")

    private let budgetOptions = ["$", "$$", "$$$"]
    private let skillOptions = ["Beginner", "Intermediate", "Advanced"]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Create Your New Project")
                        .font(.title)
                        .bold()

                    // Project title field
                    TextField("Project Title", text: $title)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)

                    // Project description field
                    TextField("Project Description", text: $goal, axis: .vertical)
                        .lineLimit(4...8)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)

                    // Budget picker
                    VStack(alignment: .leading) {
                        Text("Budget")
                        Picker("Budget", selection: $budget) {
                            ForEach(budgetOptions, id: \ .self) { option in
                                Text(option).tag(option)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                    }

                    // Skill level picker
                    VStack(alignment: .leading) {
                        Text("Skill Level")
                        Picker("Skill Level", selection: $skillLevel) {
                            ForEach(skillOptions, id: \ .self) { option in
                                Text(option).tag(option)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                    }

                    // Room photo section
                    Text("Add your room photo")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    HStack(spacing: 16) {
                        // Button to trigger a room scan (using RoomPlan or ARKit)
                        Button(action: {
                            // TODO: Present your AR scan view here if needed.
                            // You might toggle a state variable to show a sheet or full screen cover.
                        }) {
                            VStack {
                                Image(systemName: "viewfinder.circle")
                                    .font(.largeTitle)
                                Text("Scan room")
                            }
                            .frame(maxWidth: .infinity, minHeight: 120)
                            .background(Color.purple.opacity(0.15))
                            .foregroundColor(.purple)
                            .cornerRadius(14)
                        }

                        // Photos picker for uploading a room photo
                        PhotosPicker(selection: $selectedItem, matching: .images) {
                            VStack {
                                Image(systemName: "photo")
                                    .font(.largeTitle)
                                Text("Upload Photo")
                            }
                            .frame(maxWidth: .infinity, minHeight: 120)
                            .background(Color.purple.opacity(0.05))
                            .foregroundColor(.purple)
                            .cornerRadius(14)
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(Color.purple, lineWidth: 1)
                            )
                        }
                        .onChange(of: selectedItem) { newItem in
                            // Load the selected image's data asynchronously
                            Task {
                                if let data = try? await newItem?.loadTransferable(type: Data.self) {
                                    selectedImageData = data
                                }
                            }
                        }
                    }

                    // Button to generate AI plan with preview
                    Button(action: {
                        createProject(withPreview: true)
                    }) {
                        Text(isSubmitting ? "Submitting…" : "Generate AI Plan + Preview")
                            .frame(maxWidth: .infinity, minHeight: 50)
                            .background(isSubmitting ? Color.gray : Color.purple)
                            .foregroundColor(.white)
                            .cornerRadius(16)
                    }
                    .disabled(isSubmitting || !formIsValid)

                    // Button to create plan only
                    Button(action: {
                        createProject(withPreview: false)
                    }) {
                        Text(isSubmitting ? "Submitting…" : "Create Plan Only (No Preview)")
                            .frame(maxWidth: .infinity, minHeight: 50)
                            .background(isSubmitting ? Color.gray.opacity(0.3) : Color.white)
                            .foregroundColor(.purple)
                            .cornerRadius(16)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.purple, lineWidth: 1)
                            )
                    }
                    .disabled(isSubmitting || !formIsValid)

                    Spacer(minLength: 20)
                }
                .padding()
                // Hidden navigation link to ProjectDetailsView
                .navigationDestination(isPresented: $navigateToDetails) {
                    if let project = createdProject {
                        ProjectDetailsView(project: project)
                    } else {
                        EmptyView()
                    }
                }
            }
            .alert(isPresented: $showAlert) {
                Alert(title: Text("Error"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
            }
            .navigationTitle("New Project")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    /// Validate that the title and goal meet minimum length requirements.
    private var formIsValid: Bool {
        title.trimmingCharacters(in: .whitespacesAndNewlines).count >= 10 &&
        goal.trimmingCharacters(in: .whitespacesAndNewlines).count >= 10
    }

    /// Create a project on the backend and navigate to its details page.
    /// - Parameter withPreview: If `true`, also request an AI preview for the project.
    private func createProject(withPreview: Bool) {
        guard !isSubmitting else { return }
        isSubmitting = true
        Task {
            do {
                // Create the project using the network service
                let project = try await projectsService.createProject(
                    name: title,
                    goal: goal,
                    budget: budget
                )

                // If a photo has been selected, upload it to the server
                if let imageData = selectedImageData {
                    _ = try await projectsService.uploadPhoto(
                        projectId: project.id,
                        imageData: imageData,
                        fileName: "upload.jpg"
                    )
                }

                // If the user requested a preview, kick off the preview generation
                if withPreview {
                    _ = try await projectsService.requestPreview(projectId: project.id)
                }

                // Update state to navigate to the details view for this project
                createdProject = project
                navigateToDetails = true

                // Reset form fields for the next project
                title = ""
                goal = ""
                selectedImageData = nil
            } catch {
                // Present any network or decoding errors to the user
                alertMessage = error.localizedDescription
                showAlert = true
            }
            isSubmitting = false
        }
    }
}
