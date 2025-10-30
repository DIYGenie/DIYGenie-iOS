//
//  NewProjectView.swift
//  DIYGenieApp
//

import SwiftUI
import PhotosUI

struct NewProjectView: View {
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isFocused: Bool

    @State private var name = ""
    @State private var goal = ""
    @State private var budget = "$$"
    @State private var skill = "intermediate"

    @State private var showingCamera = false
    @State private var showingPicker = false
    @State private var showingOverlay = false

    @State private var selectedImage: UIImage?
    @State private var projectId: String?
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var isLoading = false

    // Service instance
    @State private var service: ProjectsService?

    // MARK: - View
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 28/255, green: 26/255, blue: 40/255),
                    Color(red: 58/255, green: 35/255, blue: 110/255)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    header

                    groupBox {
                        TextField("e.g. Floating Shelves", text: $name)
                            .focused($isFocused)
                            .padding(12)
                            .background(.black.opacity(0.2))
                            .cornerRadius(12)
                            .foregroundColor(.white)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.words)
                    } label: { label("Project Name") }

                    groupBox {
                        ZStack(alignment: .topLeading) {
                            TextEditor(text: $goal)
                                .focused($isFocused)
                                .frame(minHeight: 120)
                                .padding(8)
                                .background(.black.opacity(0.2))
                                .cornerRadius(12)
                                .foregroundColor(.white)
                            if goal.isEmpty {
                                Text("Describe what you'd like to build…")
                                    .foregroundColor(.white.opacity(0.35))
                                    .padding(.top, 16)
                                    .padding(.leading, 12)
                            }
                        }
                    } label: { label("Goal / Description") }

                    budgetSection
                    skillSection

                    if selectedImage == nil {
                        photoButtons
                    } else {
                        savedPhotoSection
                        generateButtons
                    }

                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 60)
            }
            .onTapGesture { hideKeyboard() }
        }
        // MARK: - Sheets
        .sheet(isPresented: $showingPicker) {
            ImagePicker(sourceType: .photoLibrary) { image in
                if let img = image { Task { await handleUploadFlow(image: img) } }
            }
        }
        .fullScreenCover(isPresented: $showingOverlay) {
            if let img = selectedImage, let id = projectId, let userId = UserDefaults.standard.string(forKey: "user_id") {
                RectangleOverlayView(
                    image: img,
                    projectId: id,
                    userId: userId,
                    onCancel: { showingOverlay = false },
                    onComplete: { _ in
                        showingOverlay = false
                        alertMessage = "Measurement area saved."
                        showAlert = true
                    },
                    onError: { error in
                        alertMessage = error.localizedDescription
                        showAlert = true
                    }
                )
            }
        }
        .alert("Status", isPresented: $showAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(alertMessage)
        }
        .task {
            if let userId = UserDefaults.standard.string(forKey: "user_id") {
                service = ProjectsService(userId: userId)
            }
        }
    }

    // MARK: - Header
    private var header: some View {
        HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "chevron.left")
                    .foregroundColor(.white.opacity(0.9))
                    .font(.system(size: 18, weight: .semibold))
            }
            Spacer()
        }
        .padding(.top, 8)
        .overlay(alignment: .center) {
            VStack(spacing: 4) {
                Text("New Project")
                    .font(.system(size: 34, weight: .bold))
                    .foregroundColor(.white)
                Text("Plan your next project like a pro")
                    .foregroundColor(.white.opacity(0.7))
                    .font(.subheadline)
            }
        }
    }

    // MARK: - Budget
    private var budgetSection: some View {
        groupBox {
            Picker("Budget", selection: $budget) {
                Text("$").tag("$")
                Text("$$").tag("$$")
                Text("$$$").tag("$$$")
            }
            .pickerStyle(.segmented)
            Text("Estimate your total spend level.")
                .font(.footnote)
                .foregroundColor(.white.opacity(0.6))
        } label: { label("Budget") }
    }

    // MARK: - Skill
    private var skillSection: some View {
        groupBox {
            Picker("Skill", selection: $skill) {
                Text("Beginner").tag("beginner")
                Text("Intermediate").tag("intermediate")
                Text("Advanced").tag("advanced")
            }
            .pickerStyle(.segmented)
            Text("How handy are you with tools?")
                .font(.footnote)
                .foregroundColor(.white.opacity(0.6))
        } label: { label("Skill Level") }
    }

    // MARK: - Photo Buttons
    private var photoButtons: some View {
        VStack(spacing: 14) {
            Button {
                hideKeyboard()
                Task { await handleCameraFlow() }
            } label: {
                heroButton("Take Photo for Measurements")
            }
            .disabled(!formIsValid)

            Button {
                hideKeyboard()
                showingPicker = true
            } label: {
                secondaryButton("Upload Photo")
            }
            .disabled(!formIsValid)
        }
    }

    // MARK: - Saved Photo
    private var savedPhotoSection: some View {
        VStack(spacing: 8) {
            HStack(spacing: 14) {
                if let img = selectedImage {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 64, height: 64)
                        .clipped()
                        .cornerRadius(12)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("Photo saved")
                        .foregroundColor(.white)
                        .font(.headline)
                    Text("Ready to generate your plan.")
                        .foregroundColor(.white.opacity(0.7))
                        .font(.subheadline)
                }
                Spacer()
            }
            Button("Redo / Remove") {
                selectedImage = nil
                projectId = nil
            }
            .font(.footnote.weight(.semibold))
            .foregroundColor(.white.opacity(0.8))
            .padding(.top, 4)
        }
        .padding(.top, 10)
    }

    // MARK: - Generate Buttons
    private var generateButtons: some View {
        VStack(spacing: 14) {
            Button {
                Task {
                    guard let id = projectId, let svc = service else { return }
                    do {
                        try await svc.generatePreview(projectId: id)
                        try await svc.generatePlanOnly(projectId: id)
                        alertMessage = "See your project before you build it — includes materials, tools, cuts & time plan."
                        showAlert = true
                    } catch {
                        alertMessage = "Preview generation failed: \(error.localizedDescription)"
                        showAlert = true
                    }
                }
            } label: {
                heroButton("Generate AI Plan + Preview")
                    .overlay(alignment: .bottom) {
                        Text("See your project before you build it — includes materials, tools, cuts & time plan.")
                            .font(.footnote)
                            .foregroundColor(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                            .padding(.bottom, 10)
                    }
            }
            .disabled(projectId == nil || isLoading)

            Button {
                Task {
                    guard let id = projectId, let svc = service else { return }
                    do {
                        try await svc.generatePlanOnly(projectId: id)
                        alertMessage = "Get a step-by-step DIY plan without the visual preview."
                        showAlert = true
                    } catch {
                        alertMessage = "Plan generation failed: \(error.localizedDescription)"
                        showAlert = true
                    }
                }
            } label: {
                secondaryButton("Create Plan Only")
                    .overlay(alignment: .bottom) {
                        Text("Get a step-by-step DIY plan without the visual preview.")
                            .font(.footnote)
                            .foregroundColor(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                            .padding(.bottom, 10)
                    }
            }
            .disabled(projectId == nil || isLoading)
        }
        .padding(.top, 8)
    }

    // MARK: - Logic
    private var formIsValid: Bool {
        !name.isEmpty && goal.count >= 15
    }

    private func handleCameraFlow() async {
        guard formIsValid else {
            alertMessage = "Please fill all required fields first."
            showAlert = true
            return
        }
        guard let svc = service else { return }

        isLoading = true
        do {
            let project = try await svc.createProject(
                name: name,
                goal: goal,
                budget: budget,
                skillLevel: skill
            )
            projectId = project.id
            showingCamera = false
            selectedImage = UIImage() // placeholder until RectangleOverlay starts
            showingOverlay = true
        } catch {
            alertMessage = "Error creating project: \(error.localizedDescription)"
            showAlert = true
        }
        isLoading = false
    }

    private func handleUploadFlow(image: UIImage) async {
        guard formIsValid else {
            alertMessage = "Please fill all required fields first."
            showAlert = true
            return
        }
        guard let svc = service else { return }

        isLoading = true
        do {
            let project = try await svc.createProject(
                name: name,
                goal: goal,
                budget: budget,
                skillLevel: skill
            )
            projectId = project.id
            try await svc.uploadImage(projectId: project.id, image: image)
            selectedImage = image
        } catch {
            alertMessage = "Upload failed: \(error.localizedDescription)"
            showAlert = true
        }
        isLoading = false
    }

    // MARK: - UI Helpers
    private func groupBox<Content: View>(
        @ViewBuilder content: () -> Content,
        label: () -> Text
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            label()
            content()
        }
        .padding(16)
        .background(Color.white.opacity(0.07))
        .cornerRadius(16)
    }

    private func label(_ text: String) -> Text {
        Text(text.uppercased())
            .font(.system(size: 14, weight: .semibold))
            .foregroundColor(.white.opacity(0.9))
    }

    private func heroButton(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 18, weight: .bold))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                LinearGradient(colors: [
                    Color(red: 115/255, green: 73/255, blue: 224/255),
                    Color(red: 146/255, green: 86/255, blue: 255/255)
                ], startPoint: .leading, endPoint: .trailing)
            )
            .foregroundColor(.white)
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.25), radius: 12, x: 0, y: 8)
    }

    private func secondaryButton(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 17, weight: .semibold))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .background(Color.white.opacity(0.08))
            .overlay(RoundedRectangle(cornerRadius: 14)
                .stroke(Color.white.opacity(0.18), lineWidth: 1))
            .foregroundColor(.white)
            .cornerRadius(14)
    }

    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),
                                        to: nil, from: nil, for: nil)
    }
}
