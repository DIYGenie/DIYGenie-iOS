//
//  NewProjectView.swift
//  DIYGenieApp
//

import SwiftUI
import PhotosUI
import AVFoundation

#if canImport(RoomPlan)
import RoomPlan
#endif

struct NewProjectView: View {
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isFocused: Bool

    // Form
    @State private var name = ""
    @State private var goal = ""
    @State private var budget = "$$"                 // '$', '$$', '$$$'
    @State private var skill = "beginner"            // 'beginner', 'intermediate', 'advanced'

    // Media / flow
    @State private var showingCamera = false
    @State private var showingPicker = false
    @State private var showingOverlay = false
    @State private var showingARScanner = false
    @State private var capturedImage: UIImage?
    @State private var projectId: String?
    @State private var createdProject: Project?

    // Navigation
    @State private var goToDetails = false

    // UX
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var isLoading = false

    private let api = ProjectsService(
        userId: UserDefaults.standard.string(forKey: "user_id") ?? UUID().uuidString
    )

    var body: some View {
        ZStack {
            background

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    header

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
                                Text("Beginner").tag("beginner")
                                Text("Intermediate").tag("intermediate")
                                Text("Advanced").tag("advanced")
                            }
                            .pickerStyle(.segmented)
                            .tint(Color.purple.opacity(0.9))

                            Text("Your current DIY experience.")
                                .font(.caption2)
                                .foregroundColor(.white.opacity(0.6))
                        }
                    }

                    // Media
                    if let image = capturedImage {
                        photoPreview(image)
                    } else {
                        VStack(spacing: 14) {
                            Button { showingCamera = true } label: {
                                primaryButton("Take Photo of Project Area")
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
                ProgressView().scaleEffect(1.4).tint(.white)
            }
        }

        // Hidden navigation trigger → Project Details
        .background(
            NavigationLink(
                destination: {
                    if let p = createdProject {
                        ProjectDetailsView(project: p)
                    } else {
                        EmptyView()
                    }
                },
                isActive: $goToDetails
            ) { EmptyView() }
            .hidden()
        )

        // Camera
        .sheet(isPresented: $showingCamera) {
            ImagePicker(sourceType: .camera) { image in
                if let image {
                    capturedImage = image
                    showingOverlay = true
                }
            }
        }

        // Library
        .sheet(isPresented: $showingPicker) {
            ImagePicker(sourceType: .photoLibrary) { image in
                if let image {
                    capturedImage = image
                    Task { await createProjectAndUpload(image) }
                }
            }
        }

        // Rectangle overlay (existing)
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
                        alert("Error: \(error.localizedDescription)")
                    }
                )
            }
        }

        // AR Scanner (optional add-on)
        .sheet(isPresented: $showingARScanner) {
            if let pid = projectId {
                #if canImport(RoomPlan)
                if #available(iOS 17.0, *) {
                    ARRoomPlanSheet(projectId: pid) { tempURL in
                        Task {
                            do {
                                try await api.uploadARScan(projectId: pid, fileURL: tempURL)
                                alert("AR scan saved ✅")
                            } catch {
                                alert("AR upload failed: \(error.localizedDescription)")
                            }
                        }
                    }
                } else {
                    Text("RoomPlan requires iOS 17+.")
                        .foregroundColor(.white)
                        .padding()
                        .background(.black)
                }
                #else
                Text("AR scanning not supported on this build.")
                    .foregroundColor(.white)
                    .padding()
                    .background(.black)
                #endif
            } else {
                Text("Create the project first.")
                    .foregroundColor(.white)
                    .padding()
                    .background(.black)
            }
        }

        .alert("Status", isPresented: $showAlert) { Button("OK", role: .cancel) {} } message: { Text(alertMessage) }
    }

    // MARK: - UI blocks

    private var background: some View {
        LinearGradient(
            colors: [
                Color(red: 28/255, green: 26/255, blue: 40/255),
                Color(red: 60/255, green: 35/255, blue: 126/255)
            ],
            startPoint: .topLeading, endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }

    private var header: some View {
        HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "chevron.left")
                    .foregroundColor(.white.opacity(0.9))
                    .font(.system(size: 18, weight: .semibold))
            }
            Spacer()
        }
    }

    private func photoPreview(_ image: UIImage) -> some View {
        VStack(spacing: 16) {

            // header row
            HStack(spacing: 14) {
                Image(uiImage: image)
                    .resizable().scaledToFill()
                    .frame(width: 64, height: 64).clipped().cornerRadius(12)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Photo Saved")
                        .foregroundColor(.white).font(.headline)
                    Text("Ready to generate your plan.")
                        .foregroundColor(.white.opacity(0.7)).font(.subheadline)
                }
                Spacer()
                Button("Redo") {
                    capturedImage = nil
                    projectId = nil
                    createdProject = nil
                }
                .font(.footnote)
                .foregroundColor(.white.opacity(0.7))
            }

            // MAIN ACTIONS (two buttons only)
            VStack(spacing: 12) {
                // Primary: Generate plan + preview
                Button {
                    Task {
                        guard let id = projectId, let p = createdProject else {
                            return alert("Project not created yet.")
                        }
                        await runWithSpinner {
                            _ = try await api.generatePreview(projectId: id)
                            // Auto-navigate to details after success
                            goToDetails = true
                        }
                    }
                } label: { primaryButton(isLoading ? "Generating..." : "Generate AI Plan + Preview") }
                .disabled(isLoading)

                // Secondary: Plan only (free users)
                Button {
                    Task {
                        guard let id = projectId, let _ = createdProject else {
                            return alert("Project not created yet.")
                        }
                        await runWithSpinner {
                            _ = try await api.generatePlanOnly(projectId: id)
                            // Auto-navigate to details after success
                            goToDetails = true
                        }
                    }
                } label: { secondaryButton(isLoading ? "Creating..." : "Create Plan Only (no preview)") }
                .disabled(isLoading)
            }

            // OPTIONAL AR (separate block UNDER the card/actions)
            VStack(alignment: .leading, spacing: 8) {
                Text("Optional")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
                Button {
                    #if canImport(RoomPlan)
                    if #available(iOS 17.0, *) {
                        guard AVCaptureDevice.authorizationStatus(for: .video) != .denied else {
                            alert("Camera access needed for AR scan. Enable in Settings.")
                            return
                        }
                        #if canImport(RoomPlan)
                        if !(RoomCaptureSession.isSupported) {
                            alert("AR scanning not supported on this device.")
                            return
                        }
                        #endif
                        showingARScanner = true
                    } else {
                        alert("RoomPlan requires iOS 17+.")
                    }
                    #else
                    alert("AR scanning not supported on this build.")
                    #endif
                } label: {
                    tertiaryButton("Add AR Scan for Accurate Measurements")
                }
            }
            .padding(.top, 6)
        }
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
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.1), lineWidth: 1))
        .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 3)
    }

    private func primaryButton(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 18, weight: .bold))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                LinearGradient(
                    colors: [Color(red: 115/255, green: 73/255, blue: 224/255),
                             Color(red: 146/255, green: 86/255, blue: 255/255)],
                    startPoint: .leading, endPoint: .trailing
                )
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
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.2), lineWidth: 1))
            .foregroundColor(.white)
            .cornerRadius(14)
    }

    private func tertiaryButton(_ title: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "arkit")
            Text(title)
        }
        .font(.system(size: 16, weight: .semibold))
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(Color.white.opacity(0.06))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.18), lineWidth: 1))
        .foregroundColor(.white)
        .cornerRadius(12)
    }

    // MARK: - Actions

    @MainActor
    private func createProjectAndUpload(_ image: UIImage) async {
        guard !name.isEmpty, goal.count >= 5 else {
            return alert("Please fill all required fields.")
        }
        isLoading = true
        defer { isLoading = false }

        do {
            print("🟠 Starting project creation...")
            let project = try await api.createProject(name: name, goal: goal, budget: budget, skillLevel: skill)
            self.projectId = project.id
            self.createdProject = project
            try await api.uploadImage(projectId: project.id, image: image)
            alert("Project created successfully ✅")
        } catch {
            alert("Error: \(error.localizedDescription)")
        }
    }

    @MainActor
    private func runWithSpinner(_ work: @escaping () async throws -> Void) async {
        isLoading = true
        defer { isLoading = false }
        do { try await work() } catch { alert("Error: \(error.localizedDescription)") }
    }

    @MainActor
    private func alert(_ message: String) {
        alertMessage = message
        showAlert = true
    }

    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

#if canImport(RoomPlan)
@available(iOS 17.0, *)
private struct ARRoomPlanSheet: UIViewControllerRepresentable {
    let projectId: String
    let onExport: (URL) -> Void

    func makeCoordinator() -> Coordinator { Coordinator(onExport: onExport) }

    func makeUIViewController(context: Context) -> RoomCaptureViewController {
        let vc = RoomCaptureViewController()
        vc.captureSession.delegate = context.coordinator
        vc.modalPresentationStyle = .fullScreen
        return vc
    }

    func updateUIViewController(_ uiViewController: RoomCaptureViewController, context: Context) { }

    final class Coordinator: NSObject, RoomCaptureSessionDelegate {
        private let onExport: (URL) -> Void
        private var hasExported = false

        init(onExport: @escaping (URL) -> Void) {
            self.onExport = onExport
        }

        func captureSession(_ session: RoomCaptureSession, didUpdate room: CapturedRoom) {
            // no-op for live updates
        }

        func captureSession(_ session: RoomCaptureSession, didEndWith data: CapturedRoomData, error: Error?) {
            guard !hasExported else { return }
            hasExported = true
            if let error = error {
                print("RoomPlan error:", error.localizedDescription)
                return
            }
            let tmp = FileManager.default.temporaryDirectory
                .appendingPathComponent("scan-\(UUID().uuidString).usdz")
            do {
                try data.export(to: tmp)
                onExport(tmp)
            } catch {
                print("Export failed:", error.localizedDescription)
            }
        }
    }
}
#endif

