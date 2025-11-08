import SwiftUI

struct NewProjectView: View {

    // MARK: – State
    @Environment(\.dismiss) private var dismiss

    @AppStorage("newProj_name") private var draftName: String = ""
    @AppStorage("newProj_goal") private var draftGoal: String = ""

    @State private var name: String = ""
    @State private var goal: String = ""
    @State private var budget: BudgetSelection = .two
    @State private var skill: SkillSelection = .intermediate

    // media + overlays
    @State private var selectedUIImage: UIImage?
    @State private var isShowingCamera = false
    @State private var isShowingLibrary = false
    @State private var areaSelected = false

    // AR
    @State private var projectId: String?
    @State private var showAR = false

    // navigation
    @State private var createdProject: Project?
    @State private var goToDetail = false

    // misc UI
    @State private var isLoading = false
    @State private var alertMessage = ""
    @State private var showAlert = false

    private let service = ProjectsService(
        userId: UserDefaults.standard.string(forKey: "user_id") ?? UUID().uuidString
    )

    // MARK: – Background
    private let bgGradient = Gradient(colors: [Color("BGStart"), Color("BGEnd")])
    private var background: some View {
        LinearGradient(gradient: bgGradient, startPoint: .topLeading, endPoint: .bottomTrailing)
            .ignoresSafeArea()
    }

    // MARK: – Computed
    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty &&
        !goal.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    // MARK: – Body
    var body: some View {
        ZStack {
            background
            form
        }
        // hidden navigation: when CTAs complete we jump to details
        .background(
            NavigationLink(
                destination: Group {
                    if let p = createdProject {
                        ProjectDetailsView(project: p)
                    } else {
                        EmptyView()
                    }
                },
                isActive: $goToDetail
            ) { EmptyView() }
        )
        .hidden()
        
        
        .sheet(isPresented: $isShowingCamera) {
            ImagePicker(sourceType: .camera) { ui in
                guard let ui else { return }
                selectedUIImage = ui
                Task { await createIfNeededAndUpload(ui) }     // auto-create + upload
            }
            .ignoresSafeArea()
        }
        .sheet(isPresented: $isShowingLibrary) {
            ImagePicker(sourceType: .photoLibrary) { ui in
                guard let ui else { return }
                selectedUIImage = ui
                Task { await createIfNeededAndUpload(ui) }     // auto-create + upload
            }
            .ignoresSafeArea()
        }
        // Rectangle overlay — only once per photo attach (provides real value!)
        .sheet(isPresented: .constant(selectedUIImage != nil && projectId != nil && !areaSelected)) {
            if let img = selectedUIImage, let pid = projectId {
                RectangleOverlayView(
                    image: img,
                    projectId: pid,
                    userId: service.userId,
                    onCancel: { areaSelected = true }, // let user bail, but don't block flow
                    // NewProjectView.swift  (inside the .sheet for RectangleOverlayView, onComplete:)
                    onComplete: { normalized in
                        Task { @MainActor in
                            do {
                                try await service.saveCropRect(projectId: pid, normalized: normalized)
                                if let id = projectId {
                                    createdProject = try await service.fetchProject(projectId: id) // ✅ correct label
                                }
                                alert("Area saved ✅")
                                areaSelected = true
                            } catch {
                                alert("Saving area failed:\n\(error.localizedDescription)")
                                areaSelected = true
                            }
                        }
                    },
                    onError: { err in
                        alert("Overlay error: \(err.localizedDescription)")
                        areaSelected = true
                    }

                )
            } else {
                Text("Preparing overlay…").padding()
            }
        }
        // AR (RoomPlan) sheet — enabled after project exists
        // NewProjectView.swift (AR sheet)
        .sheet(isPresented: $showAR) {
            if let pid = projectId {
                if #available(iOS 17.0, *) {
                    ARRoomPlanSheet(projectId: pid) { fileURL in
                        Task { @MainActor in
                            do {
                                try await service.uploadARScan(projectId: pid, fileURL: fileURL)
                                if let id = projectId {
                                    createdProject = try await service.fetchProject(projectId: id) // ✅
                                }
                                alert("AR scan attached to your project ✅")
                            } catch {
                                alert("Failed to attach AR scan:\n\(error.localizedDescription)")
                            }
                        }
                    }
                } else {
                    Text("RoomPlan requires iOS 17+").padding()
                }
            } else {
                Text("Create the project first").padding()
            }
        }
        .onAppear {
            if name.isEmpty { name = draftName }
            if goal.isEmpty { goal = draftGoal }
        }
        .onChange(of: name) { draftName = $0 }
        .onChange(of: goal) { draftGoal = $0 }
        .alert("Status", isPresented: $showAlert) {
            Button("OK", role: .cancel) {}
        } message: { Text(alertMessage) }
    }

    // MARK: – Form
    private var form: some View {
        ScrollView {
            VStack(spacing: 18) {

                header("New Project")

                sectionCard {
                    sectionLabel("Project name")
                    TextField("E.g. Floating shelves", text: $name)
                        .textInputAutocapitalization(.words)
                        .submitLabel(.done)
                        .padding()
                        .background(Color.white.opacity(0.08))
                        .cornerRadius(12)
                }

                sectionCard {
                    sectionLabel("Goal / description")
                    TextEditor(text: $goal)
                        .frame(minHeight: 120)
                        .padding(12)
                        .background(Color.white.opacity(0.08))
                        .cornerRadius(12)
                }

                // Budget + Skill pills (kept simple)
                sectionCard {
                    sectionLabel("Budget")
                    HStack {
                        pill("$", isOn: budget == .one) { budget = .one }
                        pill("$$", isOn: budget == .two) { budget = .two }
                        pill("$$$", isOn: budget == .three) { budget = .three }
                    }
                    helper("Your project budget range.")
                }

                sectionCard {
                    sectionLabel("Skill level")
                    HStack {
                        pill("Beginner", isOn: skill == .beginner) { skill = .beginner }
                        pill("Intermediate", isOn: skill == .intermediate) { skill = .intermediate }
                        pill("Advanced", isOn: skill == .advanced) { skill = .advanced }
                    }
                    helper("Your current DIY experience.")
                }

                // Photo section
                sectionCard {
                    sectionLabel("Room photo")

                    if let img = selectedUIImage {
                        ProjectCard(image: Image(uiImage: img),
                                    title: "Photo attached",
                                    subtitle: areaSelected ? "Area selected ✓" : "Use AR or retake a photo if needed.")
                            .padding(.bottom, 6)

                        Button("Retake") { isShowingCamera = true }
                            .font(.headline)
                            .foregroundColor(Color("Accent"))
                    } else {
                        actionRow(systemName: "photo.on.rectangle", title: "Add a room photo") {
                            isShowingLibrary = true
                        }
                        actionRow(systemName: "camera.viewfinder", title: "Take Photo for Measurements") {
                            isShowingCamera = true
                        }
                    }
                }

                // AR row — enabled after project is created (picture attached triggers auto-create)
                if projectId != nil {
                    // NewProjectView.swift (where your "Add AR Scan Accuracy" row renders)
                    tappableRow(
                        icon: "viewfinder.rectangle",
                        title: "Add AR Scan Accuracy",
                        subtitle: areaSelected ? "Improve measurements with Room Scan" : "Create the project first",
                        enabled: areaSelected
                    ) {
                        showAR = true          // ✅ will open the AR sheet above
                    }

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
                    .disabled(isLoading || !isValid)

                    secondaryCTA(title: "Create Plan Only (no preview)") {
                        Task { await createWithoutPreview() }
                    }
                    .disabled(isLoading || !isValid)
                }
                .padding(.top, 6)

                Spacer(minLength: 40)
            }
            .padding(18)
        }
        .hideKeyboardOnTap() // ← from your Keyboard.swift helper
        .disabled(isLoading)
    }

    // MARK: – Actions

    /// Create the project if needed, then upload the selected image.
    private func createIfNeededAndUpload(_ image: UIImage) async {
        isLoading = true
        defer { isLoading = false }

        do {
            if projectId == nil {
                let p = try await service.createProject(
                    name: name,
                    goal: goal,
                    budget: budget.rawValue,
                    skillLevel: skill.rawValue
                )
                projectId = p.id
                createdProject = p
            }
            if let id = projectId {
                try await service.uploadImage(projectId: id, image: image)
            }
        } catch {
            alert("Failed to attach photo: \(error.localizedDescription)")
        }
    }

    private func createWithPreview() async {
        guard isValid else { alert("Fill name and goal first."); return }
        isLoading = true
        defer { isLoading = false }

        do {
            // ensure project exists
            if projectId == nil {
                let p = try await service.createProject(
                    name: name,
                    goal: goal,
                    budget: budget.rawValue,
                    skillLevel: skill.rawValue
                )
                projectId = p.id
                createdProject = p
            }
            guard let id = projectId else { return }
            _ = try await service.generatePreview(projectId: id)
            // refresh & navigate
            createdProject = try await service.fetchProject(projectId: id)
            goToDetail = true
        } catch {
            alert("Preview failed: \(error.localizedDescription)")
        }
    }

    private func createWithoutPreview() async {
        guard isValid else { alert("Fill name and goal first."); return }
        isLoading = true
        defer { isLoading = false }

        do {
            if projectId == nil {
                let p = try await service.createProject(
                    name: name,
                    goal: goal,
                    budget: budget.rawValue,
                    skillLevel: skill.rawValue
                )
                projectId = p.id
                createdProject = p
            }
            guard let id = projectId else { return }
            _ = try await service.generatePlanOnly(projectId: id)
            createdProject = try await service.fetchProject(projectId: id)
            goToDetail = true
        } catch {
            alert("Plan-only failed: \(error.localizedDescription)")
        }
    }

    private func alert(_ text: String) {
        alertMessage = text
        showAlert = true
    }
}

// MARK: – Tiny UI helpers (kept in this file for brevity)

private func header(_ title: String) -> some View {
    VStack(alignment: .leading, spacing: 6) {
        Text(title).font(.largeTitle.bold()).foregroundColor(.white)
        Text("Get everything you need to bring your next DIY idea to life.")
            .foregroundColor(.white.opacity(0.7))
    }
    .frame(maxWidth: .infinity, alignment: .leading)
}

private func sectionCard<V: View>(_ inner: @escaping () -> V) -> some View {
    VStack(alignment: .leading, spacing: 12, content: inner)
        .padding(16)
        .background(Color.white.opacity(0.06))
        .cornerRadius(16)
}

private func sectionLabel(_ title: String) -> some View {
    Text(title.uppercased())
        .font(.caption.weight(.semibold))
        .foregroundColor(.white.opacity(0.7))
}

private func helper(_ text: String) -> some View {
    Text(text).font(.footnote).foregroundColor(.white.opacity(0.55))
}

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

private func actionRow(systemName: String, title: String, action: @escaping () -> Void) -> some View {
    Button(action: action) {
        HStack(spacing: 14) {
            Image(systemName: systemName).font(.title3)
            Text(title).font(.headline)
            Spacer()
            Image(systemName: "chevron.right").opacity(0.5)
        }
        .foregroundColor(.white)
        .padding()
        .background(Color.white.opacity(0.08))
        .cornerRadius(12)
    }
}

private func tappableRow(
    icon: String,
    title: String,
    subtitle: String,
    enabled: Bool,
    action: @escaping () -> Void
) -> some View {
    Button(action: { if enabled { action() } }) {
        HStack(spacing: 14) {
            Image(systemName: icon).font(.title3)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.headline)
                Text(subtitle).font(.footnote).opacity(0.7)
            }
            Spacer()
            Image(systemName: "chevron.right").opacity(0.5)
        }
        .foregroundColor(.white)
        .padding()
        .background(Color.white.opacity(enabled ? 0.08 : 0.04))
        .cornerRadius(12)
        .opacity(enabled ? 1 : 0.5)
    }
}

private func primaryCTA(title: String, action: @escaping () -> Void) -> some View {
    Button(action: action) {
        Text(title)
            .font(.headline.weight(.semibold))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(LinearGradient(colors: [Color("Accent"), Color.purple], startPoint: .leading, endPoint: .trailing))
            .foregroundColor(.white)
            .cornerRadius(16)
    }
}

private func secondaryCTA(title: String, action: @escaping () -> Void) -> some View {
    Button(action: action) {
        Text(title)
            .font(.headline.weight(.semibold))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Color.white.opacity(0.08))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.2), lineWidth: 1))
            .foregroundColor(.white)
            .cornerRadius(14)
    }
}

// MARK: - UI helpers (drop-in)

@ViewBuilder
private func header(_ title: String) -> some View {
    Text(title)
        .font(.largeTitle.bold())
        .foregroundColor(Color("TextPrimary", bundle: .main).opacity(0.95))
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 6)
}

@ViewBuilder
private func sectionLabel(_ text: String) -> some View {
    Text(text.uppercased())
        .font(.caption.weight(.semibold))
        .foregroundColor(.white.opacity(0.6))
        .frame(maxWidth: .infinity, alignment: .leading)
}

private func sectionCard<Content: View>(
    @ViewBuilder _ content: () -> Content
) -> some View {
    VStack(alignment: .leading, spacing: 12) {
        content()
    }
    .padding(16)
    .background(Color.white.opacity(0.06))
    .cornerRadius(16)
}

private func pill(_ text: String, selected: Bool) -> some View {
    Text(text)
        .font(.headline.weight(.semibold))
        .foregroundColor(selected ? .white : .white.opacity(0.75))
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(selected ? Color("Accent") : Color.white.opacity(0.08))
        )
}

private func tappableRow(
    icon: String,
    title: String,
    subtitle: String,
    enabled: Bool = true,
    action: @escaping () -> Void
) -> some View {
    Button(action: action) {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.title3.weight(.semibold))
                .frame(width: 28, height: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.headline).foregroundColor(.white)
                Text(subtitle).font(.subheadline).foregroundColor(.white.opacity(0.6))
            }
            Spacer()
            Image(systemName: "chevron.right").opacity(0.4)
        }
        .padding(16)
        .background(Color.white.opacity(0.06))
        .cornerRadius(16)
        .opacity(enabled ? 1 : 0.5)
    }
    .disabled(!enabled)
}

private func primaryCTA(title: String, action: @escaping () -> Void) -> some View {
    Button(action: action) {
        Text(title)
            .font(.headline.weight(.semibold))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                LinearGradient(
                    colors: [
                        Color(red: 115/255, green: 73/255, blue: 224/255),
                        Color(red: 146/255, green: 86/255, blue: 255/255)
                    ],
                    startPoint: .leading, endPoint: .trailing
                )
            )
            .cornerRadius(18)
    }
}

private func secondaryCTA(title: String, action: @escaping () -> Void) -> some View {
    Button(action: action) {
        Text(title)
            .font(.headline.weight(.semibold))
            .foregroundColor(Color("TextPrimary"))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(RoundedRectangle(cornerRadius: 18).fill(Color.white.opacity(0.08)))
    }
}
