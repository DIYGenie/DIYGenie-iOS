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
    @State private var pendingCropRect: CGRect?  // normalized 0..1 from RectangleOverlayView
    @State private var showOverlay = false       // fullScreenCover for rectangle overlay

    // MARK: - Sheets
    @State private var isShowingCamera = false
    @State private var isShowingLibrary = false
    @State private var showARSheet = false       // RoomPlan sheet

    // MARK: - UX state
    @State private var isLoading = false
    @State private var alertMessage: String = ""
    @State private var showAlert = false

    // MARK: - Created project / nav
    @State private var projectId: String?          // unlocks AR row
    @State private var createdProject: Project?    // used for details nav
    @State private var goToDetail = false
    @ViewBuilder
    private var detailsDestination: some View {
        if let p = createdProject {
            ProjectDetailsView(project: p)
        } else {
            EmptyView()
        }
    }
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
        // Hidden navigation (fires when CTAs finish)
        .background(
            NavigationLink(isActive: $goToDetail) {
                detailsDestination
            } label: {
                EmptyView()
            }
            .hidden()
        )

        // Camera
        .sheet(isPresented: $isShowingCamera) {
            ImagePicker(sourceType: .camera) { ui in
                guard let ui = ui else { return }
                selectedUIImage = ui
                showOverlay = true     // go to rectangle overlay immediately
            }
            .ignoresSafeArea()
        }
        // Library
        .sheet(isPresented: $isShowingLibrary) {
            ImagePicker(sourceType: .photoLibrary) { ui in
                guard let ui = ui else { return }
                selectedUIImage = ui
                showOverlay = true     // go to rectangle overlay immediately
            }
            .ignoresSafeArea()
        }
        // Rectangle overlay flow (works before project exists)
        .fullScreenCover(isPresented: $showOverlay) {
            if let img = selectedUIImage {
                RectangleOverlayView(
                    image: img,
                    projectId: projectId ?? "",
                    userId: service.userId,
                    onCancel: { showOverlay = false },
                    onComplete: { rect in
                        // Save normalized selection; if project exists we can push to backend right away later.
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
        // RoomPlan sheet (active once project exists)
        .sheet(isPresented: $showARSheet) {
            if let pid = projectId {
                if #available(iOS 17.0, *) {
                    ARRoomPlanSheet(projectId: pid) { fileURL in
                        Task {
                            await handleRoomPlanExport(fileURL)
                        }
                    }
                    .ignoresSafeArea()
                } else {
                    Text("RoomPlan requires iOS 17 or later.")
                        .padding()
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
                header

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
                                Text("Describe what you'd like to build...")
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
                            pill(title: opt.label, isOn: budget == opt) { budget = opt }
                        }
                    }
                    helper("Your project budget range.")
                }

                // Skill
                sectionCard {
                    sectionLabel("SKILL LEVEL")
                    HStack(spacing: 10) {
                        ForEach(Array(SkillSelection.allCases), id: \.self) { opt in
                            pill(title: opt.label, isOn: skill == opt) { skill = opt }
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
                                    Button("Retake", role: .cancel) {
                                        showOverlay = true
                                    }
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
                                isShowingCamera = true
                            }
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
        .disabled(isLoading)
        .overlay(alignment: .center) {
            if isLoading {
                ProgressView()
                    .scaleEffect(1.2)
                    .tint(.white)
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
            // 1) Create project (once)
            let created = try await service.createProject(
                name: name,
                goal: goal,
                budget: budget.label,
                skillLevel: skill.label
            )
            projectId = created.id

            // 2) Upload photo (if any)
            if let img = selectedUIImage {
                try await service.uploadImage(projectId: created.id, image: img)
            }

            // 3) If user selected a rectangle, try to store it (safe no-op if column missing)
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
            let fresh = try await service.fetchProject(id: created.id)

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
            try await service.uploadImage(projectId: pid, image: img)
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
            let fresh = try await service.fetchProject(id: pid)

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

// MARK: - Sections & UI helpers
private extension NewProjectView {
    var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left")
                        .font(.title2.weight(.semibold))
                        .foregroundColor(.white)
                        .padding(8)
                        .background(Color.white.opacity(0.08), in: Circle())
                }
                Spacer()
            }

            Text("New Project")
                .font(.system(size: 36, weight: .heavy))
                .foregroundColor(.white)

            Text("Get everything you need to bring your next DIY idea to life.")
                .foregroundColor(Color("TextSecondary"))
                .font(.title3)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.top, 6)
        .padding(.bottom, 4)
    }

    func sectionCard(@ViewBuilder _ content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 12) { content() }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color("Surface").opacity(0.7))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(Color("SurfaceStroke"), lineWidth: 1)
                    )
            )
    }

    func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.footnote.weight(.semibold))
            .foregroundColor(Color("TextSecondary"))
            .textCase(.uppercase)
    }

    func helper(_ text: String) -> some View {
        Text(text)
            .font(.footnote)
            .foregroundColor(Color("TextSecondary"))
    }

    func pill(title: String, isOn: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .foregroundColor(.white.opacity(isOn ? 1 : 0.9))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(isOn ? Color("Accent") : Color.white.opacity(0.08))
                )
        }
    }

    func tappableRow(icon: String, title: String, subtitle: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: { if enabled { action() } }) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.title3.weight(.semibold))
                    .frame(width: 28, height: 28)
                    .foregroundColor(enabled ? Color("Accent") : Color("AccentSoft"))
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .foregroundColor(Color("TextPrimary"))
                        .font(.headline)
                    Text(subtitle)
                        .foregroundColor(Color("TextSecondary"))
                        .font(.subheadline)
                }
                Spacer()
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.06))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color("SurfaceStroke"), lineWidth: 1)
                    )
            )
        }
        .disabled(!enabled)
    }

    func actionRow(systemName: String, title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: systemName)
                    .font(.headline)
                    .foregroundColor(Color("Accent"))
                Text(title)
                    .foregroundColor(Color("TextPrimary"))
                    .font(.headline)
                Spacer()
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.white.opacity(0.06))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color("SurfaceStroke"), lineWidth: 1)
                    )
            )
        }
    }

    func primaryCTA(title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.headline.weight(.semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color("Accent"))
                )
        }
        .opacity(isLoading ? 0.6 : 1)
    }

    func secondaryCTA(title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.headline.weight(.semibold))
                .foregroundColor(Color("TextPrimary"))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 18)
                        .fill(Color.white.opacity(0.08))
                )
        }
        .opacity(isLoading ? 0.6 : 1)
    }
}

