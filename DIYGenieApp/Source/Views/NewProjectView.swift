import SwiftUI
import UIKit

struct NewProjectView: View {

    // MARK: - State
    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var goal: String = ""
    @State private var budget: BudgetSelection = .two
    @State private var skill: SkillSelection = .intermediate

    @State private var selectedUIImage: UIImage?
    @State private var isShowingCamera = false
    @State private var isShowingLibrary = false
    @State private var isLoading = false
    @State private var alertMessage: String = ""
    @State private var showAlert = false

    // unlocks AR row + nav after create
    @State private var projectId: String?
    @State private var goToDetail = false
    @State private var createdProject: Project?

    // service
    private let service = ProjectsService(
        userId: UserDefaults.standard.string(forKey: "user_id") ?? UUID().uuidString
    )

    // MARK: - Background
    private let bgGradient = Gradient(colors: [Color("BGStart"), Color("BGEnd")])
    private var background: some View {
        LinearGradient(gradient: bgGradient, startPoint: .topLeading, endPoint: .bottomTrailing)
            .ignoresSafeArea()
    }

    // MARK: - Computed
    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty &&
        !goal.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    // MARK: - Body
    var body: some View {
        ZStack {
            background
            form

            // Hidden programmatic navigation to details
            NavigationLink(isActive: $goToDetail) {
                if let p = createdProject {
                    ProjectDetailsView(project: p)
                } else {
                    EmptyView()
                }
            } label: { EmptyView() }
            .hidden()
        }
        // Camera
        .sheet(isPresented: $isShowingCamera) {
            ImagePicker(sourceType: .camera) { ui in
                guard let ui else { return }
                selectedUIImage = ui
            }
            .ignoresSafeArea()
        }
        // Library
        .sheet(isPresented: $isShowingLibrary) {
            ImagePicker(sourceType: .photoLibrary) { ui in
                guard let ui else { return }
                selectedUIImage = ui
            }
            .ignoresSafeArea()
        }
        // AR sheet (now includes onExport)
        .sheet(isPresented: $showAR) {
            ARRoomPlanSheet(
                projectId: projectId ?? "",
                onExport: { fileURL in
                    Task {
                        do {
                            // Upload the exported scan to Supabase + update project
                            try await service.uploadARScan(projectId: projectId ?? "", fileURL: fileURL)

                            // Refresh local copy so details reflect new asset
                            if let id = projectId {
                                createdProject = try await service.fetchProject(id: id)
                            }

                            alertMessage = "AR scan attached to your project ✅"
                            showAlert = true
                        } catch {
                            alertMessage = "Failed to attach AR scan: \(error.localizedDescription)"
                            showAlert = true
                        }
                    }
                }
            )
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
                            pill(title: opt.label, isOn: budget == opt) { self.budget = opt }
                        }
                    }
                    helper("Your project budget range.")
                }

                // Skill level
                sectionCard {
                    sectionLabel("SKILL LEVEL")
                    HStack(spacing: 10) {
                        ForEach(Array(SkillSelection.allCases), id: \.self) { opt in
                            pill(title: opt.label, isOn: skill == opt) { self.skill = opt }
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
                                Text("Use AR or retake a photo if needed.")
                                    .foregroundColor(Color("TextSecondary"))
                                    .font(.subheadline)

                                Button("Retake", role: .cancel) {
                                    selectedUIImage = nil
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

                // AR row (enabled after create)
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
        .disabled(isLoading)
        .overlay(alignment: .center) {
            if isLoading {
                ProgressView()
                    .scaleEffect(1.2)
                    .tint(.white)
            }
        }
    }

    // MARK: - Sections & helpers
    private var header: some View {
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

    private func sectionCard(@ViewBuilder _ content: () -> some View) -> some View {
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

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.footnote.weight(.semibold))
            .foregroundColor(Color("TextSecondary"))
            .textCase(.uppercase)
    }

    private func helper(_ text: String) -> some View {
        Text(text)
            .font(.footnote)
            .foregroundColor(Color("TextSecondary"))
    }

    private func pill(title: String, isOn: Bool, action: @escaping () -> Void) -> some View {
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

    private func tappableRow(icon: String, title: String, subtitle: String, enabled: Bool, action: @escaping () -> Void) -> some View {
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

    private func actionRow(systemName: String, title: String, action: @escaping () -> Void) -> some View {
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

    private func primaryCTA(title: String, action: @escaping () -> Void) -> some View {
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
    }

    private func secondaryCTA(title: String, action: @escaping () -> Void) -> some View {
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
    }
}

// MARK: - Actions
private extension NewProjectView {
    func createWithPreview() async {
        guard isValid else { return alert("Please fill in name and description.") }
        guard let ui = selectedUIImage else { return alert("Add a room photo to generate the preview.") }

        isLoading = true
        defer { isLoading = false }

        do {
            // 1) Create project row first
            let project = try await service.createProject(
                name: name,
                goal: goal,
                budget: budget.label,
                skillLevel: skill.label
            )
            self.projectId = project.id
            self.createdProject = project

            // 2) Upload image and save URL
            try await service.uploadImage(projectId: project.id, image: ui)

            // 3) Trigger preview and fetch updated project (optional)
            _ = try await service.generatePreview(projectId: project.id)
            self.createdProject = try await service.fetchProject(id: project.id)

            // 4) Go to details
            goToDetail = true
        } catch {
            alert("Failed to create project: \(error.localizedDescription)")
        }
    }

    func createWithoutPreview() async {
        guard isValid else { return alert("Please fill in name and description.") }

        isLoading = true
        defer { isLoading = false }

        do {
            let project = try await service.createProject(
                name: name,
                goal: goal,
                budget: budget.label,
                skillLevel: skill.label
            )
            self.projectId = project.id
            self.createdProject = project

            // (Optional) plan-only call
            _ = try await service.generatePlanOnly(projectId: project.id)

            goToDetail = true
        } catch {
            alert("Failed to create project: \(error.localizedDescription)")
        }
    }

    func alert(_ text: String) {
        alertMessage = text
        showAlert = true
    }

    // local flag to drive AR sheet
    var showAR: Binding<Bool> {
        .init(
            get: { projectId != nil && _showAR },
            set: { _ in _showAR = $0 }
        )
    }
    @State private var _showAR = false
}

