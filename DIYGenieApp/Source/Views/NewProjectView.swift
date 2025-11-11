//
//  NewProjectView.swift
//  DIYGenieApp
//

import SwiftUI
import UIKit

struct NewProjectView: View {

    // MARK: - Services
    private let service = ProjectsService(
        userId: UserDefaults.standard.string(forKey: "user_id") ?? UUID().uuidString
    )

    // MARK: - Form state
    @State private var name: String = ""
    @State private var goal: String = ""
    @State private var budget: BudgetSelection = .two
    @State private var skill: SkillSelection = .intermediate

    // MARK: - Media / overlay
    @State private var selectedUIImage: UIImage?
    @State private var pendingCropRect: CGRect?
    @State private var showOverlay = false

    // MARK: - Sheets
    @State private var isShowingCamera = false
    @State private var isShowingLibrary = false
    @State private var showARSheet = false
    @State private var isStartingCamera = false // single-session guard

    // MARK: - UX
    @State private var isLoading = false
    @State private var alertMessage = ""
    @State private var showAlert = false

    // MARK: - Created / nav
    @State private var projectId: String?
    @State private var createdProject: Project?
    @State private var goToDetail = false

    // MARK: - BG
    private var background: some View {
        LinearGradient(gradient: Gradient(colors: [Color("BGStart"), Color("BGEnd")]),
                       startPoint: .topLeading, endPoint: .bottomTrailing)
            .ignoresSafeArea()
    }

    var body: some View {
        ZStack {
            background
            form
        }
        .background(
            NavigationLink(isActive: $goToDetail) {
                if let p = createdProject {
                    ProjectDetailsView(project: p)
                } else {
                    EmptyView()
                }
            } label: { EmptyView() }
            .hidden()
        )
        // Photo Library
        .sheet(isPresented: $isShowingLibrary) {
            ImagePicker(sourceType: .photoLibrary) { ui in
                guard let ui else { return }
                selectedUIImage = ui
                showOverlay = true
            }
            .ignoresSafeArea()
        }
        // Camera
        .sheet(isPresented: $isShowingCamera) {
            ImagePicker(sourceType: .camera) { ui in
                guard let ui else { return }
                selectedUIImage = ui
                showOverlay = true
            }
            .ignoresSafeArea()
        }
        // Overlay (works before project exists)
        .fullScreenCover(isPresented: $showOverlay) {
            if let img = selectedUIImage {
                RectangleOverlayView(
                    image: img,
                    projectId: projectId ?? "",
                    userId: service.userId,
                    onCancel: { showOverlay = false },
                    onComplete: { rect in
                        pendingCropRect = rect
                        showOverlay = false
                    },
                    onError: { err in
                        alert("Overlay error: \(err.localizedDescription)")
                        showOverlay = false
                    }
                )
            }
        }
        // AR sheet (after project exists)
        .sheet(isPresented: $showARSheet) {
            if let pid = projectId {
                if #available(iOS 17.0, *) {
                    ARRoomPlanSheet(projectId: pid) { fileURL in
                        Task { await handleRoomPlanExport(fileURL) }
                    }
                    .ignoresSafeArea()
                } else {
                    Text("RoomPlan requires iOS 17 or later.")
                        .padding()
                }
            }
        }
        .alert(alertMessage, isPresented: $showAlert) { Button("OK", role: .cancel) {} }
    }

    // MARK: - Form
    private var form: some View {
        ScrollView {
            VStack(spacing: 18) {
                header("New Project")

                // Name
                sectionCard {
                    sectionLabel("PROJECT NAME")
                    TextField("e.g. Floating shelves", text: $name)
                        .textInputAutocapitalization(.words)
                        .foregroundColor(Color("TextPrimary"))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .background(RoundedRectangle(cornerRadius: 14).fill(Color.white.opacity(0.06)))
                }

                // Goal
                sectionCard {
                    sectionLabel("GOAL / DESCRIPTION")
                    TextEditor(text: $goal)
                        .frame(minHeight: 140)
                        .scrollContentBackground(.hidden)
                        .foregroundColor(Color("TextPrimary"))
                        .padding(12)
                        .background(RoundedRectangle(cornerRadius: 14).fill(Color.white.opacity(0.06)))
                        .overlay {
                            if goal.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                Text("Describe what you'd like to build…")
                                    .foregroundColor(Color("TextSecondary"))
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 16)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                }

                // Budget
                sectionCard {
                    sectionLabel("BUDGET")
                    HStack(spacing: 10) {
                        ForEach(Array(BudgetSelection.allCases), id: \.self) { opt in
                            pill(opt.label, isOn: budget == opt) { budget = opt }
                        }
                    }
                    helper("Your project budget range.")
                }

                // Skill
                sectionCard {
                    sectionLabel("SKILL LEVEL")
                    HStack(spacing: 10) {
                        ForEach(Array(SkillSelection.allCases), id: \.self) { opt in
                            pill(opt.label, isOn: skill == opt) { skill = opt }
                        }
                    }
                    helper("Your current DIY experience.")
                }

                // Photo
                sectionCard {
                    sectionLabel("ROOM PHOTO")

                    if let img = selectedUIImage {
                        HStack(spacing: 12) {
                            Image(uiImage: img)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 96, height: 96)
                                .clipped()
                                .cornerRadius(12)

                            VStack(alignment: .leading, spacing: 6) {
                                Text("Photo attached")
                                    .foregroundColor(Color("TextPrimary"))
                                    .font(.headline)

                                if pendingCropRect != nil {
                                    Text("Area selected ✓")
                                        .font(.subheadline)
                                        .foregroundColor(Color("TextSecondary"))
                                } else {
                                    Text("Tap ‘Retake’ to set target area.")
                                        .font(.subheadline)
                                        .foregroundColor(Color("TextSecondary"))
                                }

                                HStack(spacing: 16) {
                                    Button("Retake", role: .cancel) { showOverlay = true }
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundColor(Color("Accent"))

                                    if projectId != nil {
                                        Button("Re-upload") {
                                            Task { await uploadCurrentImageIfNeeded(force: true) }
                                        }
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundColor(Color("Accent"))
                                    }
                                }
                            }
                            Spacer()
                        }
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Color("SurfaceStroke"), lineWidth: 1)
                                .fill(Color("Surface").opacity(0.6))
                        )
                    } else {
                        VStack(spacing: 12) {
                            actionRow(systemName: "photo.on.rectangle", title: "Add a room photo") {
                                isShowingLibrary = true
                            }
                            actionRow(systemName: "camera.viewfinder", title: "Take Photo for Measurements") {
                                CameraAccess.request(isStarting: $isStartingCamera,
                                                     isPresentingCamera: $isShowingCamera,
                                                     isARPresented: showARSheet,
                                                     isOverlayPresented: showOverlay) {
                                    alert("Camera permission is required to take photos.")
                                }
                            }
                        }
                    }
                }

                // AR tools section (always visible header)
                sectionLabel("AR Scan For Measurement Accuracy")

                // 1) AR Measuring Tool (on photo) — opens the rectangle overlay editor on the saved photo
                tappableRow(
                    icon: "ruler",
                    title: "AR Measuring Tool (on photo)",
                    subtitle: selectedUIImage != nil ? "Adjust target area on the attached photo" : "Add a photo first",
                    enabled: selectedUIImage != nil
                ) {
                    // Re-open the overlay editor on the current photo
                    showOverlay = true
                }

                // 2) AR Room Scan (3D) — requires project + saved photo + confirmed overlay rect
                tappableRow(
                    icon: "viewfinder.rectangular",
                    title: "AR Room Scan (3D)",
                    subtitle: (projectId == nil)
                        ? "Create the project first"
                        : (selectedUIImage == nil)
                            ? "Add a photo first"
                            : (pendingCropRect == nil)
                                ? "Confirm rectangle overlay to enable"
                                : "Improve measurements with Room Scan",
                    enabled: (projectId != nil) && (selectedUIImage != nil) && (pendingCropRect != nil)
                ) {
                    showARSheet = true
                }

                // Helper hint (always visible under AR tools)
                helper("Add a photo and confirm the rectangle overlay to enable AR tools.")

                // CTAs
                VStack(spacing: 12) {
                    primaryCTA(title: "Generate AI Plan + Preview") {
                        Task { await createAndNavigate(wantsPreview: true) }
                    }
                    .disabled(!isValid || isLoading)

                    secondaryCTA(title: "Create Plan Only (no preview)") {
                        Task { await createAndNavigate(wantsPreview: false) }
                    }
                    .disabled(!isValid || isLoading)
                }
                .padding(.top, 6)

                Spacer(minLength: 40)
            }
            .padding(18)
        }
        .disabled(isLoading)
        .overlay {
            if isLoading {
                ProgressView().scaleEffect(1.2).tint(.white)
            }
        }
    }

    // MARK: - Derived
    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty &&
        !goal.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    // MARK: - Actions
    @MainActor
    private func createAndNavigate(wantsPreview: Bool) async {
        guard isValid else { return alert("Please complete name and goal.") }
        isLoading = true
        defer { isLoading = false }

        do {
            // 1) Create
            let created = try await service.createProject(
                name: name,
                goal: goal,
                budget: budget.label,
                skillLevel: skill.label
            )
            projectId = created.id

            // 2) Upload photo (optional)
            if let img = selectedUIImage {
                _ = try await service.uploadImage(
                    projectId: created.id,
                    image: img.dg_resized(maxDimension: 2000)
                )
            }

            // 3) Attach crop rect (best effort)
            if let rect = pendingCropRect {
                await service.attachCropRectIfAvailable(projectId: created.id, rect: rect)
            }

            // 4) Trigger
            if wantsPreview {
                _ = try await service.generatePreview(projectId: created.id)
            } else {
                try await service.generatePlanOnly(projectId: created.id)
            }

            // 5) Fetch + nav
            let fresh = try await service.fetchProject(projectId: created.id)
            createdProject = fresh
            goToDetail = true

        } catch {
            alert("Failed to create project: \(error.localizedDescription)")
        }
    }

    @MainActor
    private func uploadCurrentImageIfNeeded(force: Bool = false) async {
        guard let pid = projectId, let img = selectedUIImage else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            _ = try await service.uploadImage(projectId: pid, image: img.dg_resized(maxDimension: 2000))
            alert("Photo uploaded.")
        } catch {
            alert("Upload failed: \(error.localizedDescription)")
        }
    }

    @MainActor
    private func handleRoomPlanExport(_ fileURL: URL) async {
        isLoading = true
        defer { isLoading = false }
        do {
            guard let pid = projectId else { return }
            try await service.uploadARScan(projectId: pid, fileURL: fileURL)
            let fresh = try await service.fetchProject(projectId: pid)
            createdProject = fresh
            alert("AR scan attached to your project ✅")
        } catch {
            alert("Failed to attach AR scan: \(error.localizedDescription)")
        }
    }

    private func alert(_ text: String) {
        alertMessage = text
        showAlert = true
    }
}

// MARK: - Tiny local UI helpers

@ViewBuilder
private func header(_ title: String) -> some View {
    VStack(alignment: .leading, spacing: 6) {
        Text(title).font(.largeTitle.bold()).foregroundColor(.white)
        Text("Get everything you need to bring your next DIY idea to life.")
            .foregroundColor(.white.opacity(0.7))
    }
    .frame(maxWidth: .infinity, alignment: .leading)
}

@ViewBuilder
private func sectionLabel(_ title: String) -> some View {
    Text(title.uppercased())
        .font(.caption.weight(.semibold))
        .foregroundColor(.white.opacity(0.6))
}

@ViewBuilder
private func sectionCard<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
    VStack(alignment: .leading, spacing: 12, content: content)
        .padding(16)
        .background(Color.white.opacity(0.06))
        .cornerRadius(16)
}

@ViewBuilder
private func helper(_ text: String) -> some View {
    Text(text).font(.footnote).foregroundColor(.white.opacity(0.55))
}

@ViewBuilder
private func pill(_ title: String, isOn: Bool, action: @escaping () -> Void) -> some View {
    Button(action: action) {
        Text(title)
            .font(.headline.weight(.semibold))
            .foregroundColor(.white)
            .padding(.horizontal, 18).padding(.vertical, 10)
            .background(isOn ? Color("Accent") : Color.white.opacity(0.08))
            .cornerRadius(14)
    }
}

@ViewBuilder
private func tappableRow(icon: String, title: String, subtitle: String, enabled: Bool, action: @escaping () -> Void) -> some View {
    Button(action: action) {
        HStack(spacing: 14) {
            Image(systemName: icon).imageScale(.large).frame(width: 28, height: 28)
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.headline)
                Text(subtitle).font(.footnote).foregroundColor(.white.opacity(0.6))
            }
            Spacer()
            Image(systemName: "chevron.right").opacity(0.4)
        }
        .padding(14)
        .background(Color.white.opacity(0.06))
        .cornerRadius(14)
        .opacity(enabled ? 1 : 0.5)
    }
    .disabled(!enabled)
}

@ViewBuilder
private func primaryCTA(title: String, action: @escaping () -> Void) -> some View {
    Button(action: action) {
        Text(title)
            .font(.headline.weight(.semibold))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color("Accent"))
                    .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.white.opacity(0.2), lineWidth: 1))
            )
    }
}

@ViewBuilder
private func secondaryCTA(title: String, action: @escaping () -> Void) -> some View {
    Button(action: action) {
        Text(title)
            .font(.headline.weight(.semibold))
            .foregroundColor(Color("TextPrimary"))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Color.white.opacity(0.08))
            .cornerRadius(18)
    }
}

@ViewBuilder
private func actionRow(systemName: String, title: String, action: @escaping () -> Void) -> some View {
    Button(action: action) {
        HStack(spacing: 14) {
            Image(systemName: systemName)
                .imageScale(.large)
                .frame(width: 28, height: 28)
            Text(title)
                .font(.headline)
                .foregroundColor(Color("TextPrimary"))
            Spacer()
            Image(systemName: "chevron.right")
                .opacity(0.4)
        }
        .padding(14)
        .background(Color.white.opacity(0.06))
        .cornerRadius(14)
    }
}
