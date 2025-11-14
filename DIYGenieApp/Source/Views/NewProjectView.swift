//
//  NewProjectView.swift
//  DIYGenieApp
//

import SwiftUI
import UIKit
import AVFoundation
#if canImport(RoomPlan)
import RoomPlan
#endif

struct NewProjectView: View {

    // MARK: - Services
    // Callback to notify parent when a project is created
    var onFinished: ((Project) -> Void)? = nil
    private let service = ProjectsService(
        userId: UserDefaults.standard.string(forKey: "user_id") ?? UUID().uuidString
    )

    // MARK: - Form state
    @State private var name: String = ""
    @State private var goal: String = ""
    @State private var budget: BudgetSelection = .two
    @State private var skill: SkillSelection = .intermediate

    // MARK: - Media / measurement
    @State private var selectedUIImage: UIImage?
    @State private var measurementArea: [CGPoint]?  // normalized 4 points (TL, TR, BR, BL)
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
    @State private var arAttached = false

    // MARK: - Created / nav
    @State private var projectId: String?
    @State private var createdProject: Project?

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
        // Photo Library
        .sheet(isPresented: $isShowingLibrary) {
            ImagePicker(sourceType: .photoLibrary) { ui in
                guard let ui else { return }
                selectedUIImage = ui
                // Auto-open measurement editor after selecting a photo
                showOverlay = true
            }
            .ignoresSafeArea()
        }
        // Camera
        .sheet(isPresented: $isShowingCamera) {
            ImagePicker(sourceType: .camera) { ui in
                guard let ui else { return }
                selectedUIImage = ui
                // Auto-open measurement editor after taking a photo
                showOverlay = true
            }
            .ignoresSafeArea()
        }
        // Measurement editor (works before project exists)
        .fullScreenCover(isPresented: $showOverlay) {
            if let img = selectedUIImage {
                RectangleOverlayView(
                    image: img,
                    projectId: projectId ?? "",
                    userId: service.userId,
                    onCancel: { showOverlay = false },
                    onComplete: { rect in
                        // Coerce to a centered square, then save 4 normalized corners
                        let imgSize = img.size
                        guard imgSize.width > 0, imgSize.height > 0 else { showOverlay = false; return }
                        let side = min(rect.width, rect.height)
                        let center = CGPoint(x: rect.midX, y: rect.midY)
                        let square = CGRect(x: center.x - side/2, y: center.y - side/2, width: side, height: side)
                        let tl = CGPoint(x: square.minX / imgSize.width, y: square.minY / imgSize.height)
                        let tr = CGPoint(x: square.maxX / imgSize.width, y: square.minY / imgSize.height)
                        let br = CGPoint(x: square.maxX / imgSize.width, y: square.maxY / imgSize.height)
                        let bl = CGPoint(x: square.minX / imgSize.width, y: square.maxY / imgSize.height)
                        measurementArea = [tl, tr, br, bl]
                        showOverlay = false
                        // Auto-create/attach immediately after confirming the area
                        Task { await ensureProjectAfterPhoto() }
                    },
                    onError: { err in
                        alert("Measurement editor error: \(err.localizedDescription)")
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

    // MARK: - Form (inside struct)
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

                                if measurementArea != nil {
                                    Text("Measurement area saved ✓")
                                        .font(.subheadline)
                                        .foregroundColor(Color("TextSecondary"))
                                } else {
                                    Text("Tap ‘Edit Area’ to draw a 4-point square.")
                                        .font(.subheadline)
                                        .foregroundColor(Color("TextSecondary"))
                                }

                                HStack(spacing: 16) {
                                    Button("Edit Area", role: .cancel) { showOverlay = true }
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

                // Measurements & AR
                sectionLabel("Measurements & AR Tools")

                // Only one row here: AR Room Scan (3D)
                tappableRow(
                    icon: "viewfinder.rectangular",
                    title: "AR Room Scan (3D)",
                    subtitle: arAttached
                        ? "AR scan attached ✓  Tap to rescan"
                        : (projectId == nil)
                            ? "Project will auto-create after photo"
                            : (selectedUIImage == nil)
                                ? "Add a photo first"
                                : (measurementArea == nil)
                                    ? "Draw the 4-point area to enable"
                                    : "Improve measurements with Room Scan",
                    enabled: (selectedUIImage != nil) && (measurementArea != nil)
                ) {
                    Task { @MainActor in
                        arAttached = false
                        if projectId == nil { await ensureProjectAfterPhoto() }
                        guard projectId != nil else {
                            alert("Please add a photo and draw the 4-point area to continue.")
                            return
                        }
                        guard #available(iOS 17.0, *) else {
                            alert("RoomPlan requires iOS 17 or later.")
                            return
                        }
#if canImport(RoomPlan)
                        // Device capability check (prevents black screen on unsupported devices)
                        guard RoomCaptureSession.isSupported else {
                            alert("This device doesn't support RoomPlan scanning.")
                            return
                        }
#endif
                        // Camera permission check (prevents black screen when denied)
                        let status = AVCaptureDevice.authorizationStatus(for: .video)
                        if status == .notDetermined {
                            AVCaptureDevice.requestAccess(for: .video) { granted in
                                DispatchQueue.main.async {
                                    if granted { showARSheet = true }
                                    else { alert("Camera access is required for AR scanning.") }
                                }
                            }
                            return
                        }
                        guard status == .authorized else {
                            alert("Enable Camera access in Settings to use AR scanning.")
                            return
                        }
                        showARSheet = true
                    }
                }

                helper("Add a photo + Select Area to Enable AR Scan")

                // CTAs
                VStack(spacing: 12) {
                    primaryCTA(title: "Generate AI Plan + Preview") {
                        Task { await createAndNavigate(wantsPreview: true) }
                    }
                    .disabled(!isValid || isLoading)

                    secondaryCTA(title: "Create Plan Only (No Preview)") {
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
            if isLoading { ProgressView().scaleEffect(1.2).tint(.white) }
        }
    }

    // MARK: - Derived
    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty &&
        !goal.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        selectedUIImage != nil
    }

    // MARK: - Actions
    @MainActor
    private func createAndNavigate(wantsPreview: Bool) async {
        guard isValid else {
            if selectedUIImage == nil {
                alert("Please add at least one room photo before continuing.")
            } else {
                alert("Please complete name and goal.")
            }
            return
        }
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

            // 3) Attach measurement area (best effort)
            if let points = measurementArea, let rect = denormalizedRect(from: points, image: selectedUIImage) {
                await service.attachCropRectIfAvailable(projectId: created.id, rect: rect)
            }

            // 4) Trigger
            if wantsPreview {
                _ = try await service.generatePreview(projectId: created.id)
            } else {
                try await service.generatePlanOnly(projectId: created.id)
            }

            // 5) Fetch + notify parent
            let fresh = try await service.fetchProject(projectId: created.id)
            createdProject = fresh
            onFinished?(fresh)

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
        // Close AR sheet first so RealityKit stops rendering (prevents Metal validation crash)
        showARSheet = false

        isLoading = true
        defer { isLoading = false }
        do {
            guard let pid = projectId else { return }
            try await service.uploadARScan(projectId: pid, fileURL: fileURL)
            let fresh = try await service.fetchProject(projectId: pid)
            createdProject = fresh
            arAttached = true
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

// MARK: - Tiny local UI helpers (outside struct)

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

// MARK: - Helpers used by the view (inside extension so they can access state)
extension NewProjectView {
    @MainActor
    private func ensureProjectAfterPhoto() async {
        if let pid = projectId {
            if let img = selectedUIImage {
                _ = try? await service.uploadImage(projectId: pid, image: img.dg_resized(maxDimension: 2000))
            }
            if let points = measurementArea, let rect = denormalizedRect(from: points, image: selectedUIImage) {
                await service.attachCropRectIfAvailable(projectId: pid, rect: rect)
            }
            if let fresh = try? await service.fetchProject(projectId: pid) { createdProject = fresh }
            return
        }

        // Create new project immediately
        let safeName = name.trimmingCharacters(in: .whitespaces).isEmpty ? "New Project" : name
        let safeGoal = goal.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Auto-created from photo" : goal

        isLoading = true
        defer { isLoading = false }
        do {
            let created = try await service.createProject(
                name: safeName,
                goal: safeGoal,
                budget: budget.label,
                skillLevel: skill.label
            )
            projectId = created.id

            if let img = selectedUIImage {
                _ = try? await service.uploadImage(projectId: created.id, image: img.dg_resized(maxDimension: 2000))
            }
            if let points = measurementArea, let rect = denormalizedRect(from: points, image: selectedUIImage) {
                await service.attachCropRectIfAvailable(projectId: created.id, rect: rect)
            }

            if let fresh = try? await service.fetchProject(projectId: created.id) { createdProject = fresh }
        } catch {
            alert("Couldn’t create project from photo: \(error.localizedDescription)")
        }
    }

    private func denormalizedRect(from points: [CGPoint], image: UIImage?) -> CGRect? {
        guard points.count == 4, let img = image else { return nil }
        let xs = points.map { $0.x * img.size.width }
        let ys = points.map { $0.y * img.size.height }
        guard let minX = xs.min(), let maxX = xs.max(), let minY = ys.min(), let maxY = ys.max() else { return nil }
        return CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
    }
}
