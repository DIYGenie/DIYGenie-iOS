import SwiftUI
import UIKit

struct NewProjectView: View {

    // MARK: - Environment
    @Environment(\.dismiss) private var dismiss

    // MARK: - Drafts (optional)
    @AppStorage("newProj_name") private var draftName: String = ""
    @AppStorage("newProj_goal") private var draftGoal: String = ""

    // MARK: - Form state
    @State private var name: String = ""
    @State private var goal: String = ""
    @State private var budget: BudgetSelection = .two
    @State private var skill:  SkillSelection  = .intermediate

    // MARK: - Media & overlays
    @State private var selectedUIImage: UIImage?
    @State private var areaSelected = false

    // MARK: - UI flags
    @State private var isShowingCamera = false
    @State private var isShowingLibrary = false
    @State private var showAR = false
    @State private var isLoading = false
    @State private var alertMessage = ""
    @State private var showAlert = false

    // MARK: - Navigation / created project
    @State private var projectId: String?
    @State private var createdProject: Project?
    @State private var goToDetail = false

    // MARK: - Services
    private let service = ProjectsService(
        userId: UserDefaults.standard.string(forKey: "user_id") ?? UUID().uuidString
    )

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
        .background(
            // Hidden navigation (fires after CTAs succeed)
            NavigationLink(isActive: $goToDetail) {
                if let p = createdProject { ProjectDetailsView(project: p) } else { EmptyView() }
            } label: { EmptyView() }
            .hidden()
        )
        .onAppear {
            if !draftName.isEmpty { name = draftName }
            if !draftGoal.isEmpty { goal = draftGoal }
        }
        .onChange(of: name) { draftName = $0 }
        .onChange(of: goal) { draftGoal = $0 }
        .hideKeyboardOnTap()

        // Camera
        .sheet(isPresented: $isShowingCamera) {
            ImagePicker(sourceType: .camera) { ui in
                guard let ui else { return }
                selectedUIImage = ui
                Task { await createIfNeededAndUpload(ui) }  // auto-create + upload
            }
            .ignoresSafeArea()
        }

        // Library
        .sheet(isPresented: $isShowingLibrary) {
            ImagePicker(sourceType: .photoLibrary) { ui in
                guard let ui else { return }
                selectedUIImage = ui
                Task { await createIfNeededAndUpload(ui) }  // auto-create + upload
            }
            .ignoresSafeArea()
        }

        // Rectangle overlay (only once per photo attach)
        .sheet(isPresented: .constant(selectedUIImage != nil && projectId != nil && !areaSelected)) {
            if let img = selectedUIImage, let pid = projectId {
                RectangleOverlayView(
                    image: img,
                    projectId: pid,
                    userId: service.userId,
                    onCancel: { areaSelected = true },
                    onComplete: { normalized in
                        Task {
                            do {
                                try await service.saveCropRect(projectId: pid, normalized: normalized)
                                areaSelected = true
                                alert("Area saved ✓")
                            } catch {
                                alert("Saving area failed: \(error.localizedDescription)")
                                areaSelected = true
                            }
                        }
                    },
                    onError: { err in
                        alert("Overlay error: \(err.localizedDescription)")
                        areaSelected = true
                    }
                )
                .ignoresSafeArea()
            } else {
                Text("Preparing overlay…").padding()
            }
        }

        // AR sheet (RoomPlan)
        .sheet(isPresented: $showAR) {
            if let pid = projectId {
                if #available(iOS 17.0, *) {
                    ARRoomPlanSheet(projectId: pid) { fileURL in
                        Task {
                            do {
                                try await service.uploadARScan(projectId: pid, fileURL: fileURL)
                                if let p = try? await service.fetchProject(projectId: pid) {
                                    createdProject = p
                                }
                                alert("AR scan attached to your project ✅")
                            } catch {
                                alert("Failed to attach AR scan: \(error.localizedDescription)")
                            }
                        }
                    }
                    .ignoresSafeArea()
                } else {
                    Text("RoomPlan requires iOS 17+").padding()
                }
            } else {
                Text("Create the project first").padding()
            }
        }

        // Alert
        .alert(alertMessage, isPresented: $showAlert) {
            Button("OK", role: .cancel) { }
        }
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

                // Goal / Description
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

                // Skill level
                sectionCard {
                    sectionLabel("SKILL LEVEL")
                    HStack(spacing: 10) {
                        ForEach(Array(SkillSelection.allCases), id: \.self) { opt in
                            pill(title: opt.label, isOn: skill == opt) { skill = opt }
                        }
                    }
                    helper("Your current DIY experience.")
                }

                // Room photo
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

                                HStack(spacing: 6) {
                                    if areaSelected {
                                        Text("Area selected ✓")
                                            .foregroundColor(Color("TextSecondary"))
                                            .font(.subheadline)
                                    } else {
                                        Text("Adjust your target area…")
                                            .foregroundColor(Color("TextSecondary"))
                                            .font(.subheadline)
                                    }
                                }

                                Button("Retake", role: .cancel) {
                                    selectedUIImage = nil
                                    areaSelected = false
                                    isShowingCamera = true
                                }
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(Color("Accent"))
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
                    ) { showAR = true }
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
                        Task { await createWithPreview() }
                    }
                    secondaryCTA(title: "Create Plan Only (no preview)") {
                        Task { await createWithoutPreview() }
                    }
                }
                .padding(.top, 6)

                Spacer(minLength: 40)
            }
            .padding(18)
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }
            }
        }
        .disabled(isLoading)
        .overlay(alignment: .center) {
            if isLoading {
                ProgressView().scaleEffect(1.2).tint(.white)
            }
        }
    }
}

// MARK: - Sections & UI helpers
extension NewProjectView {

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
                .background(RoundedRectangle(cornerRadius: 20).fill(Color("Accent")))
        }
        .disabled(isLoading)
        .opacity(isLoading ? 0.6 : 1)
    }

    func secondaryCTA(title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.headline.weight(.semibold))
                .foregroundColor(Color("TextPrimary"))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(RoundedRectangle(cornerRadius: 18).fill(Color.white.opacity(0.08)))
        }
        .disabled(isLoading)
        .opacity(isLoading ? 0.6 : 1)
    }
}

// MARK: - Actions
extension NewProjectView {

    @MainActor
    func createIfNeededAndUpload(_ ui: UIImage) async {
        do {
            isLoading = true

            // 1) Create project if missing
            if createdProject == nil {
                let p = try await service.createProject(
                    name: name.isEmpty ? "Untitled" : name,
                    goal: goal.isEmpty ? "—" : goal,
                    budget: budget.label,
                    skillLevel: skill.label
                )
                createdProject = p
                projectId = p.id
            }

            // 2) Upload image → save URL
            if let id = projectId {
                try await service.uploadImage(projectId: id, image: ui)
            }
        } catch {
            alert("Photo attach failed: \(error.localizedDescription)")
        }
        isLoading = false
    }

    func createWithPreview() async {
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else { return alert("Please enter a project name.") }
        guard !goal.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return alert("Please enter a goal/description.") }

        isLoading = true
        defer { isLoading = false }

        do {
            let id: String
            if let existing = projectId {
                id = existing
            } else {
                let p = try await service.createProject(
                    name: name,
                    goal: goal,
                    budget: budget.label,
                    skillLevel: skill.label
                )
                createdProject = p
                projectId = p.id
                id = p.id
            }

            // kick off preview generation (ignore URL here; Details loads it)
            _ = try? await service.generatePreview(projectId: id)

            // refresh + navigate
            if let p = try? await service.fetchProject(projectId: id) {
                createdProject = p
            }
            goToDetail = true
        } catch {
            alert("Failed to create project: \(error.localizedDescription)")
        }
    }

    func createWithoutPreview() async {
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else { return alert("Please enter a project name.") }
        guard !goal.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return alert("Please enter a goal/description.") }

        isLoading = true
        defer { isLoading = false }

        do {
            let id: String
            if let existing = projectId {
                id = existing
            } else {
                let p = try await service.createProject(
                    name: name,
                    goal: goal,
                    budget: budget.label,
                    skillLevel: skill.label
                )
                createdProject = p
                projectId = p.id
                id = p.id
            }

            _ = try? await service.generatePlanOnly(projectId: id)

            if let p = try? await service.fetchProject(projectId: id) {
                createdProject = p
            }
            goToDetail = true
        } catch {
            alert("Failed to create project: \(error.localizedDescription)")
        }
    }

    func alert(_ text: String) {
        alertMessage = text
        showAlert = true
    }
}

// MARK: - Small helper to dismiss keyboard on tap
private extension View {
    func hideKeyboardOnTap() -> some View {
        self.onTapGesture {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
    }
}

