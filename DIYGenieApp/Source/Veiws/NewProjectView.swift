import SwiftUI
import PhotosUI

struct NewProjectView: View {
    @State private var title = ""
    @State private var goal = ""
    @State private var budget = "$"
    @State private var skillLevel = "Beginner"
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImageData: Data?
    @State private var isScanning = false
    @State private var isSubmitting = false
    @State private var showAlert = false
    @State private var alertMessage = ""

    // Use your actual UUID here.
    private let projectsService = ProjectsService(userId: "99198c4b-8470-49e2-895c-75593c5aa181")

    private let budgetOptions = ["$", "$$", "$$$"]
    private let skillOptions = ["Beginner", "Intermediate", "Advanced"]

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Create Your New Project")
                        .font(.largeTitle.bold())

                    // Project title
                    TextField("Project name (min 10 chars)", text: $title)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)

                    // Project description
                    TextField("Describe your goal (min 10 chars)", text: $goal, axis: .vertical)
                        .lineLimit(3...6)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)

                    // Budget picker
                    VStack(alignment: .leading) {
                        Text("Budget")
                        Picker("Budget", selection: $budget) {
                            ForEach(budgetOptions, id: \.self) { option in
                                Text(option).tag(option)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }

                    // Skill level picker
                    VStack(alignment: .leading) {
                        Text("Skill Level")
                        Picker("Skill Level", selection: $skillLevel) {
                            ForEach(skillOptions, id: \.self) { option in
                                Text(option).tag(option)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }

                    // Scan / Upload buttons
                    HStack(spacing: 16) {
                        Button {
                            // trigger AR scan sheet
                            isScanning = true
                        } label: {
                            VStack {
                                Image(systemName: "viewfinder.circle")
                                    .font(.largeTitle)
                                Text("Scan room")
                            }
                            .frame(maxWidth: .infinity, minHeight: 100)
                            .background(Color.purple.opacity(0.15))
                            .foregroundColor(.purple)
                            .cornerRadius(16)
                        }
                        PhotosPicker(selection: $selectedItem, matching: .images) {
                            VStack {
                                Image(systemName: "photo")
                                    .font(.largeTitle)
                                Text("Upload photo")
                            }
                            .frame(maxWidth: .infinity, minHeight: 100)
                            .background(Color.purple.opacity(0.05))
                            .foregroundColor(.purple)
                            .cornerRadius(16)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.purple, lineWidth: 1)
                            )
                        }
                        .onChange(of: selectedItem) { newItem in
                            Task {
                                if let data = try? await newItem?.loadTransferable(type: Data.self) {
                                    selectedImageData = data
                                }
                            }
                        }
                    }

                    // Generate AI Plan + Preview button
                    Button {
                        createProject(withPreview: true)
                    } label: {
                        Text(isSubmitting ? "Submitting…" : "Generate AI Plan + Preview")
                            .frame(maxWidth: .infinity, minHeight: 50)
                            .background(isSubmitting ? Color.gray : Color.purple)
                            .foregroundColor(.white)
                            .cornerRadius(16)
                    }
                    .disabled(isSubmitting || title.count < 10 || goal.count < 10)

                    // Create Plan Only button
                    Button {
                        createProject(withPreview: false)
                    } label: {
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
                    .disabled(isSubmitting || title.count < 10 || goal.count < 10)

                    Spacer(minLength: 40)
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .alert(isPresented: $showAlert) {
                Alert(title: Text("Error"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
            }
        }
    }

    /// Creates a project and optionally requests a preview.
    private func createProject(withPreview: Bool) {
        guard !isSubmitting else { return }
        isSubmitting = true
        Task {
            do {
                // Create project
                let project = try await projectsService.createProject(
                    name: title,
                    goal: goal,
                    budget: budget
                )

                // If user selected a photo, upload it
                if let imageData = selectedImageData {
                    _ = try await projectsService.uploadPhoto(
                        projectId: project.id,
                        imageData: imageData,
                        fileName: "upload.jpg"
                    )
                }

                // Optionally request preview
                if withPreview {
                    _ = try await projectsService.requestPreview(projectId: project.id)
                }

                // Reset form or navigate away here if needed
                title = ""
                goal = ""
                selectedImageData = nil
            } catch {
                alertMessage = error.localizedDescription
                showAlert = true
            }
            isSubmitting = false
        }
    }
}
