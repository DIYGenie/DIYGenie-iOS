//
//  NewProjectView.swift
//  DIYGenieApp
//

import SwiftUI
import PhotosUI

struct NewProjectView: View {
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isFocused: Bool

    // MARK: - Form State
    @State private var name = ""
    @State private var goal = ""
    @State private var budget = "$$"
    @State private var skill = "intermediate"

    // MARK: - Media + Flow
    @State private var showingCamera = false
    @State private var showingPicker = false
    @State private var showingOverlay = false
    @State private var capturedImage: UIImage?
    @State private var projectId: String?

    // MARK: - UI Flags
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var isLoading = false

    private let api = ProjectsService(
        userId: UserDefaults.standard.string(forKey: "user_id") ?? "demo"
    )

    // MARK: - Body
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
                    // Header
                    HStack {
                        Button(action: { dismiss() }) {
                            Image(systemName: "chevron.left")
                                .foregroundColor(.white.opacity(0.9))
                                .font(.system(size: 18, weight: .semibold))
                        }
                        Spacer()
                    }

                    Text("New Project")
                        .font(.system(size: 34, weight: .bold))
                        .foregroundColor(.white)
                    Text("Plan your next project like a pro")
                        .foregroundColor(.white.opacity(0.7))

                    // Project Name
                    groupBox {
                        TextField("e.g. Floating Shelves", text: $name)
                            .focused($isFocused)
                            .padding(12)
                            .background(.black.opacity(0.2))
                            .cornerRadius(12)
                            .foregroundColor(.white)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.words)
                    } label: {
                        label("Project Name")
                    }

                    // Goal / Description
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
                    } label: {
                        label("Goal / Description")
                    }

                    // Budget Picker
                    groupBox {
                        Picker("Budget", selection: $budget) {
                            Text("$").tag("$")
                            Text("$$").tag("$$")
                            Text("$$$").tag("$$$")
                        }
                        .pickerStyle(.segmented)
                        Text("Estimated project cost level.")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.5))
                    } label: {
                        label("Budget")
                    }

                    // Skill Picker
                    groupBox {
                        Picker("Skill", selection: $skill) {
                            Text("Beginner").tag("beginner")
                            Text("Intermediate").tag("intermediate")
                            Text("Advanced").tag("advanced")
                        }
                        .pickerStyle(.segmented)
                        Text("Your current DIY experience.")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.5))
                    } label: {
                        label("Skill Level")
                    }

                    // MARK: - Photo Area
                    if capturedImage == nil {
                        VStack(spacing: 14) {
                            Button {
                                isFocused = false
                                showingCamera = true
                            } label: {
                                heroButton("Take Photo for Measurements")
                            }

                            Button {
                                isFocused = false
                                showingPicker = true
                            } label: {
                                secondaryButton("Upload Photo")
                            }
                        }
                    } else {
                        photoPreviewSection
                    }

                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 60)
            }
            .onTapGesture { hideKeyboard() }
        }

        // MARK: - Camera
        .sheet(isPresented: $showingCamera) {
            ImagePicker(sourceType: .camera) { image in
                if let image = image {
                    showingCamera = false
                    capturedImage = image
                    showingOverlay = true
                }
            }
        }

        // MARK: - Photo Library
        .sheet(isPresented: $showingPicker) {
            ImagePicker(sourceType: .photoLibrary) { image in
                if let image = image {
                    capturedImage = image
                    Task { await createProjectAndUpload(image) }
                }
            }
        }

        // MARK: - Overlay
        .fullScreenCover(isPresented: $showingOverlay) {
            if let image = capturedImage {
                RectangleOverlayView(
                    image: image,
                    projectId: projectId ?? "",
                    userId: UserDefaults.standard.string(forKey: "user_id") ?? "",
                    onCancel: { showingOverlay = false },
                    onComplete: { roi in
                        showingOverlay = false
                        Task { await createProjectAndUpload(image) }
                    },
                    onError: { error in
                        showingOverlay = false
                        alertMessage = "Error: \(error.localizedDescription)"
                        showAlert = true
                    }
                )
            }
        }

        .alert("Status", isPresented: $showAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
    }

    // MARK: - Components
    private var photoPreviewSection: some View {
        VStack(spacing: 14) {
            HStack(spacing: 14) {
                Image(uiImage: capturedImage!)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 64, height: 64)
                    .clipped()
                    .cornerRadius(12)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Photo Saved")
                        .foregroundColor(.white)
                        .font(.headline)
                    Text("Ready to generate your plan.")
                        .foregroundColor(.white.opacity(0.7))
                        .font(.subheadline)
                }
                Spacer()
                Button("Redo") {
                    capturedImage = nil
                    projectId = nil
                }
                .font(.footnote)
                .foregroundColor(.white.opacity(0.7))
            }

            VStack(spacing: 14) {
                Button {
                    Task {
                        if let id = projectId {
                            isLoading = true
                            try? await api.generatePreview(projectId: id)
                            isLoading = false
                            alertMessage = "Preview request sent successfully."
                            showAlert = true
                        }
                    }
                } label: {
                    heroButton("Generate AI Plan + Preview")
                        .overlay(buttonDetail("Visual mockup of your space + step-by-step plan, materials, tools, cuts, time & cost."))
                }
                .disabled(projectId == nil || isLoading)

                Button {
                    Task {
                        if let id = projectId {
                            isLoading = true
                            try? await api.generatePlanOnly(projectId: id)
                            isLoading = false
                            alertMessage = "Plan request sent successfully."
                            showAlert = true
                        }
                    }
                } label: {
                    secondaryButton("Create Plan Only")
                        .overlay(buttonDetail("Full DIY plan without visual preview."))
                }
                .disabled(projectId == nil || isLoading)
            }
        }
    }

    // MARK: - Networking
    private func createProjectAndUpload(_ image: UIImage) async {
        guard !name.isEmpty, goal.count >= 15 else {
            alertMessage = "Please fill all required fields before continuing."
            showAlert = true
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            let project = try await api.createProject(
                name: name,
                goal: goal,
                budget: budget,
                skillLevel: skill
            )
            projectId = project.id
            try await api.uploadImage(projectId: project.id, image: image)
        } catch {
            alertMessage = "Error: \(error.localizedDescription)"
            showAlert = true
        }
    }

    // MARK: - UI Helpers
    private func groupBox<Content: View>(@ViewBuilder content: () -> Content, label: () -> Text) -> some View {
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
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.18), lineWidth: 1))
            .foregroundColor(.white)
            .cornerRadius(14)
    }

    private func buttonDetail(_ text: String) -> some View {
        VStack {
            Spacer()
            Text(text)
                .font(.caption)
                .foregroundColor(.white.opacity(0.6))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 8)
                .padding(.bottom, 4)
        }
    }

    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
