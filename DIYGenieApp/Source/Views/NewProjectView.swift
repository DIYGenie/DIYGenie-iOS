//
//  NewProjectView.swift
//  DIYGenieApp
//

import SwiftUI
import PhotosUI
import QuickLook

struct NewProjectView: View {
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isFocused: Bool

    // Form
    @State private var name = ""
    @State private var goal = ""
    @State private var budget = "$$"
    @State private var skill = "intermediate"

    // Media / flow
    @State private var showingCamera = false
    @State private var showingPicker = false
    @State private var showingOverlay = false
    @State private var capturedImage: UIImage?
    @State private var projectId: String?

    // 🧩 AR Preview
    @State private var showingARPreview = false
    @State private var arFileURL: URL?

    // UX state
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var isLoading = false

    private let api = ProjectsService(
        userId: UserDefaults.standard.string(forKey: "user_id") ?? "demo"
    )

    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [
                    Color(red: 28/255, green: 26/255, blue: 40/255),
                    Color(red: 60/255, green: 35/255, blue: 126/255)
                ],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {

                    // Header
                    HStack {
                        Button(action: { dismiss() }) {
                            Image(systemName: "chevron.left")
                                .foregroundColor(.white.opacity(0.9))
                                .font(.system(size: 18, weight: .semibold))
                        }
                        Spacer()
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("New Project")
                            .font(.system(size: 36, weight: .heavy))
                            .foregroundStyle(.white)
                            .shadow(color: .white.opacity(0.08), radius: 6, x: 0, y: 1)

                        Text("Bring your next DIY idea to life with a photo or room scan.")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                            .lineSpacing(2)
                    }

                    // Name
                    glassField(label: "Project Name") {
                        TextField("e.g. Floating Shelves", text: $name)
                            .italic()
                            .focused($isFocused)
                            .padding(12)
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                            .foregroundColor(.white)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.words)
                    }

                    // Goal
                    glassField(label: "Goal / Description") {
                        ZStack(alignment: .topLeading) {
                            TextEditor(text: $goal)
                                .focused($isFocused)
                                .frame(minHeight: 120)
                                .padding(8)
                                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                                .foregroundColor(.white)
                            if goal.isEmpty {
                                Text("Describe what you'd like to build…")
                                    .italic()
                                    .foregroundColor(.white.opacity(0.35))
                                    .padding(.top, 16)
                                    .padding(.leading, 12)
                            }
                        }
                    }

                    // Budget
                    glassField(label: "Budget") {
                        VStack(spacing: 6) {
                            Picker("Budget", selection: $budget) {
                                Text("$").tag("$")
                                Text("$$").tag("$$")
                                Text("$$$").tag("$$$")
                            }
                            .pickerStyle(.segmented)
                            .tint(Color.purple.opacity(0.9))

                            Text("Your project budget range.")
                                .font(.caption2)
                                .foregroundColor(.white.opacity(0.6))
                        }
                    }

                    // Skill
                    glassField(label: "Skill Level") {
                        VStack(spacing: 6) {
                            Picker("Skill", selection: $skill) {
                                Text("Easy").tag("easy")
                                Text("Medium").tag("medium")
                                Text("Hard").tag("hard")
                            }
                            .pickerStyle(.segmented)
                            .tint(Color.purple.opacity(0.9))

                            Text("Your current DIY experience.")
                                .font(.caption2)
                                .foregroundColor(.white.opacity(0.6))
                        }
                    }

                    // Photo section
                    if let image = capturedImage {
                        photoPreview(image)
                    } else {
                        VStack(spacing: 14) {
                            Button { showingCamera = true } label: {
                                primaryButton("Take Photo for Measurements")
                            }
                            Button { showingPicker = true } label: {
                                secondaryButton("Upload Photo")
                            }
                        }
                    }

                    Spacer(minLength: 60)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 80)
            }
            .onTapGesture { hideKeyboard() }

            if isLoading {
                Color.black.opacity(0.25).ignoresSafeArea()
                ProgressView()
                    .progressViewStyle(.circular)
                    .scaleEffect(1.4)
                    .tint(.white)
            }
        }

        // Camera picker
        .sheet(isPresented: $showingCamera) {
            ImagePicker(sourceType: .camera) { image in
                if let image {
                    capturedImage = image
                    showingOverlay = true
                }
            }
        }

        // Library picker
        .sheet(isPresented: $showingPicker) {
            ImagePicker(sourceType: .photoLibrary) { image in
                if let image {
                    capturedImage = image
                    Task { await createProjectAndUpload(image) }
                }
            }
        }

        // Overlay for rectangle measurement
        .fullScreenCover(isPresented: $showingOverlay) {
            if let image = capturedImage {
                RectangleOverlayView(
                    image: image,
                    projectId: projectId ?? "",
                    userId: UserDefaults.standard.string(forKey: "user_id") ?? "",
                    onCancel: { showingOverlay = false },
                    onComplete: { _ in
                        showingOverlay = false
                        Task { await createProjectAndUpload(image) }
                    },
                    onError: { error in
                        showingOverlay = false
                        alertMessage = error.localizedDescription
                        showAlert = true
                    }
                )
            }
        }

        // AR Preview sheet
        .sheet(isPresented: $showingARPreview) {
            if let url = arFileURL {
                ARQuickLookView(url: url)
            } else {
                Text("No 3D scan available yet.")
                    .font(.headline)
                    .padding()
            }
        }

        .alert("Status", isPresented: $showAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
    }

    // MARK: - Photo Preview
    private func photoPreview(_ image: UIImage) -> some View {
        VStack(spacing: 14) {

            HStack(spacing: 14) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 64, height: 64)
                    .clipped()
                    .cornerRadius(12)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Photo Saved")
                        .foregroundColor(.white)
                        .font(.headline)
                    Text("Ready to generate your plan or view 3D scan.")
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
                        guard let id = projectId else {
                            alert("Project not created yet.")
                            return
                        }
                        await runWithSpinner {
                            let url = try await api.generatePreview(projectId: id)
                            alert("Preview generated successfully ✅\n\(url)")
                        }
                    }
                } label: {
                    primaryButton(isLoading ? "Generating..." : "Generate AI Plan + Preview")
                }
                .disabled(isLoading)

                Button {
                    Task {
                        guard let id = projectId else {
                            alert("Project not created yet.")
                            return
                        }
                        await runWithSpinner {
                            _ = try await api.generatePlanOnly(projectId: id)
                            alert("AI plan created successfully ✅")
                        }
                    }
                } label: {
                    secondaryButton(isLoading ? "Creating..." : "Create Plan Only")
                }
                .disabled(isLoading)

                // 🧩 AR Preview Button (shows only if file exists)
                if let url = arFileURL {
                    Button {
                        showingARPreview = true
                    } label: {
                        secondaryButton("Preview 3D Scan (AR)")
                    }
                }
            }
        }
    }

    // MARK: - Networking
    @MainActor
    private func createProjectAndUpload(_ image: UIImage) async {
        guard !name.isEmpty, goal.count >= 15 else {
            alertMessage = "Please fill all required fields."
            showAlert = true
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            print("🟠 Starting project creation...")

            let project = try await api.createProject(
                name: name,
                goal: goal,
                budget: budget,
                skillLevel: skill
            )

            DispatchQueue.main.async {
                self.projectId = project.id
                print("🟢 Saved projectId to state:", self.projectId ?? "nil")
            }

            try await api.uploadImage(projectId: project.id, image: image)
            print("🟩 Image upload finished for project:", project.id)

            // 👇 Placeholder for when AR scan file exists later
            // self.arFileURL = URL(string: project.reference_object ?? "")

            alertMessage = "Project created successfully ✅"
            showAlert = true

        } catch {
            print("🔴 Error creating or uploading project:", error.localizedDescription)
            alertMessage = "Error: \(error.localizedDescription)"
            showAlert = true
        }
    }

    // MARK: - Helpers
    @MainActor
    private func runWithSpinner<T>(_ work: @escaping () async throws -> T) async rethrows -> T {
        isLoading = true
        defer { isLoading = false }
        return try await work()
    }

    @MainActor
    private func runWithSpinner(_ work: @escaping () async throws -> Void) async {
        isLoading = true
        do { try await work() }
        catch { alert("Error: \(error.localizedDescription)") }
        isLoading = false
    }

    @MainActor
    private func alert(_ message: String) {
        alertMessage = message
        showAlert = true
    }

    private func glassField<Content: View>(label: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label.uppercased())
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white.opacity(0.9))
            content()
        }
        .padding(16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 3)
    }

    private func primaryButton(_ title: String) -> some View {
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
            .shadow(color: .black.opacity(0.25), radius: 8, x: 0, y: 4)
    }

    private func secondaryButton(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 17, weight: .semibold))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .background(Color.white.opacity(0.08))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
            .foregroundColor(.white)
            .cornerRadius(14)
    }

    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),
                                        to: nil, from: nil, for: nil)
    }
}

// MARK: - AR QuickLook Wrapper
struct ARQuickLookView: UIViewControllerRepresentable {
    let url: URL
    func makeUIViewController(context: Context) -> QLPreviewController {
        let controller = QLPreviewController()
        controller.dataSource = context.coordinator
        return controller
    }
    func updateUIViewController(_ controller: QLPreviewController, context: Context) {}
    func makeCoordinator() -> Coordinator { Coordinator(self) }
    final class Coordinator: NSObject, QLPreviewControllerDataSource {
        let parent: ARQuickLookView
        init(_ parent: ARQuickLookView) { self.parent = parent }
        func numberOfPreviewItems(in controller: QLPreviewController) -> Int { 1 }
        func previewController(_ controller: QLPreviewController,
                               previewItemAt index: Int) -> QLPreviewItem {
            parent.url as QLPreviewItem
        }
    }
}

