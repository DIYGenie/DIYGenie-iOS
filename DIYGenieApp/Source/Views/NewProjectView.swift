import SwiftUI
import UIKit

struct NewProjectView: View {

    // MARK: - Env / Services
    @Environment(\.dismiss) private var dismiss
    private let service = ProjectsService(
        userId: UserDefaults.standard.string(forKey: "user_id") ?? UUID().uuidString
    )

    // MARK: - Form state
    @State private var name: String = ""
    @State private var goal: String = ""
    @State private var budget: BudgetSelection = .two
    @State private var skill: SkillSelection = .intermediate

    // MARK: - Media & overlay
    @State private var selectedUIImage: UIImage?
    @State private var pendingCropRect: CGRect?      // normalized (0..1) rect from overlay
    @State private var showOverlay = false           // fullScreenCover for rectangle overlay

    // MARK: - Sheets & nav
    @State private var isShowingCamera = false
    @State private var isShowingLibrary = false
    @State private var showARSheet = false
    @State private var goToDetail = false

    // MARK: - Created project
    @State private var projectId: String?            // unlocks AR row
    @State private var createdProject: Project?      // nav destination

    // MARK: - UX state
    @State private var isLoading = false
    @State private var alertMessage = ""
    @State private var showAlert = false

    // MARK: - Background
    private let bgGradient = Gradient(colors: [Color("BGStart"), Color("BGEnd")])
    private var background: some View {
        LinearGradient(gradient: bgGradient, startPoint: .topLeading, endPoint: .bottomTrailing)
            .ignoresSafeArea()
    }

    // MARK: - Body
    var body: some View {
        ZStack {
            background
            form
        }
        // Hidden navigation trigger → details
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
        // Camera
        .sheet(isPresented: $isShowingCamera) {
            ImagePicker(sourceType: .camera) { ui in
                guard let ui = ui else { return }
                selectedUIImage = ui
                showOverlay = true
            }
            .ignoresSafeArea()
        }
        // Library
        .sheet(isPresented: $isShowingLibrary) {
            ImagePicker(sourceType: .photoLibrary) { ui in
                guard let ui = ui else { return }
                selectedUIImage = ui
                showOverlay = true
            }
            .ignoresSafeArea()
        }
        // Rectangle overlay (runs BEFORE project exists)
        .fullScreenCover(isPresented: $showOverlay) {
            if let img = selectedUIImage {
                RectangleOverlayView(
                    image: img,
                    projectId: projectId ?? "",
                    userId: service.userId,
                    onCancel: { showOverlay = false },
                    onComplete: { rect in
                        // 1) Save normalized crop locally
                        pendingCropRect = rect
                        showOverlay = false
                        // 2) Auto-create project if needed and upload the image + crop
                        Task { await createIfNeededAndUpload(img) }
                    },
                    onError: { err in
                        alert("Overlay error: \(err.localizedDescription)")
                        showOverlay = false
                    }
                )
            }
        }
        // RoomPlan (AR) sheet — only active once project exists
        .sheet(isPresented: $showARSheet) {
            if let pid = projectId {
                if #available(iOS 17.0, *) {
                    ARRoomPlanSheet(projectId: pid) { fileURL in
                        Task { await handleRoomPlanExport(fileURL) }
                    }
                    .ignoresSafeArea()
                } else {
                    Text("RoomPlan requires iOS 17 or later.").padding()
                }
            }
        }
        // Alerts
        .alert(alertMessage, isPresented: $showAlert) { Button("OK", role: .cancel) {} }
    }

    // MARK: - Form
    private var form: some View {
        ScrollView {
            VStack(spacing: 18) {
                header("New Project")

                // Project name
                sectionCard {
                    sectionLabel("PROJECT NAME")
                    TextField("e.g. Floating Shelves", text: $name)
                        .textInputAutocapitalization(.words)
                        .foregroundColor(Color("TextPrimary"))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color.white.opacity(0.06))
                        )
                }

                // Goal
                sectionCard {
                    sectionLabel("GOAL / DESCRIPTION")
                    TextEditor(text: $goal)
                        .frame(minHeight: 140)
                        .scrollContentBackground(.hidden)
                        .foregroundColor(Color("TextPrimary"))
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color.white.opacity(0.06))
                        )
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

                // Photo block
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
                                    Text("Tap 'Retake' to set target area.")
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
                            actionRow(systemName: "photo.on.rectangle",
                                      title: "Add a room photo") { isShowingLibrary = true }
                            actionRow(systemName: "camera.viewfinder",
                                      title: "Take Photo for Measurements") { isShowingCamera = true }
                        }
                    }
                }

                // AR row
                if projectId != nil {
                    tappableRow(
                        icon: "viewfinder.rectangular",
                        title: "Add AR Scan Accuracy",
                        subtitle: "Improve measurements with Room Scan",
                        enabled: true
                    ) { showARSheet = true }
                } else {
                    tappableRow(
                        icon: "viewfinder.rectangular",
                        title: "Add AR Scan Accuracy",
                        subtitle: "Create the project first",
                        enabled: false,
                        action: {}
                    )
                }

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
        .hideKeyboardOnTap()
        .disabled(isLoading)
        .overlay {
            if isLoading { ProgressView().scaleEffect(1.2).tint(.white) }
        }
    }

    // MARK: - Derived
    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty &&
        !goal.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    // MARK: - Actions

    /// Auto-creates project (if needed) right after overlay confirm,
    /// uploads the photo, saves crop, refreshes, and enables AR row.
    @MainActor
    private func createIfNeededAndUpload(_ ui: UIImage) async {
        isLoading = true
        defer { isLoading = false }

        do {
            // 1) Ensure we have a project ID
            let pid: String
            if let existing = projectId {
                pid = existing
            } else {
                let fallbackName = name.trimmingCharacters(in: .whitespaces).isEmpty ? "Untitled Project" : name
                let created = try await service.createProject(
                    name: fallbackName,
                    goal: goal.isEmpty ? " " : goal,
                    budget: budget.label,
                    skillLevel: skill.label
                )
                pid = created.id
                projectId = pid
                createdProject = created
            }

            // 2) Upload the photo
            _ = try await service.uploadImage(projectId: pid, image: ui)

            // 3) Save crop (safe no-op if column missing)
            if let rect = pendingCropRect {
                await service.attachCropRectIfAvailable(projectId: pid, rect: rect)
            }

            // 4) Refresh local copy
            createdProject = try await service.fetchProject(projectId: pid)

        } catch {
            alert("Photo upload failed: \(error.localizedDescription)")
        }
    }

    @MainActor
    private func createAndNavigate(wantsPreview: Bool) async {
        guard isValid else { return alert("Please complete name and goal.") }
        isLoading = true
        defer { isLoading = false }

        do {
            // 1) Create project (once)
            let created = try await service.createProject(
                name: name,
                goal: goal,
                budget: budget.label,
                skillLevel: skill.label
            )
            projectId = created.id

            // 2) Upload image if present
            if let img = selectedUIImage {
                _ = try await service.uploadImage(projectId: created.id, image: img)
            }

            // 3) Attach crop if present
            if let rect = pendingCropRect {
                await service.attachCropRectIfAvailable(projectId: created.id, rect: rect)
            }

            // 4) Kick off plan/preview
            if wantsPreview {
                _ = try await service.generatePreview(projectId: created.id)
            } else {
                _ = try await service.generatePlanOnly(projectId: created.id)
            }

            // 5) Refresh + navigate
            createdProject = try await service.fetchProject(projectId: created.id)
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
            _ = try await service.uploadImage(projectId: pid, image: img)
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
            createdProject = try await service.fetchProject(projectId: pid)
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

// MARK: - Local UI helpers (scoped to this file only)

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
private func tappableRow(
    icon: String,
    title: String,
    subtitle: String,
    enabled: Bool,
    action: @escaping () -> Void
) -> some View {
    Button(action: action) {
        HStack(spacing: 14) {
            Image(systemName: icon).imageScale(.large)
                .frame(width: 28, height: 28)
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
        HStack(spacing: 12) {
            Image(systemName: systemName)
                .imageScale(.large)
                .frame(width: 28, height: 28)
            Text(title)
                .frame(maxWidth: .infinity, alignment: .leading)
            Image(systemName: "chevron.right").opacity(0.35)
        }
        .padding(14)
        .background(Color.white.opacity(0.06))
        .cornerRadius(14)
    }
}

