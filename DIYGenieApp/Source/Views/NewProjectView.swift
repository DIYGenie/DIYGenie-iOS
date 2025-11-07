import SwiftUI

// MARK: - Simple enums (no $ symbols)
enum BudgetSelection: CaseIterable, Equatable {
    case one, two, three
    var label: String {
        switch self {
        case .one:   return "$"
        case .two:   return "$$"
        case .three: return "$$$"
        }
    }
}

enum SkillSelection: String, CaseIterable, Equatable {
    case beginner, intermediate, advanced
    var label: String { rawValue.capitalized }
}

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

    // set after successful create
    @State private var projectId: UUID?

    // MARK: - View
    var body: some View {
        ZStack {
            // Spotify-style purple/black gradient using your asset names directly
            LinearGradient(
                colors: [Color("BGStart"), Color("BGEnd")],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 18) {

                    // Header
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
                            .overlay(
                                Group {
                                    if goal.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                        Text("Describe what you'd like to build...")
                                            .foregroundColor(Color("TextSecondary"))
                                            .padding(.horizontal, 20)
                                            .padding(.vertical, 16)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                    }
                                }
                            )
                    }

                    // Budget
                    sectionCard {
                        sectionLabel("BUDGET")
                        HStack(spacing: 10) {
                            ForEach(BudgetSelection.allCases, id: \.self) { opt in
                                pill(title: opt.label, isOn: budget == opt) {
                                    budget = opt
                                }
                            }
                        }
                        helper("Your project budget range.")
                    }

                    // Skill level
                    sectionCard {
                        sectionLabel("SKILL LEVEL")
                        HStack(spacing: 10) {
                            ForEach(SkillSelection.allCases, id: \.self) { opt in
                                pill(title: opt.label, isOn: skill == opt) {
                                    skill = opt
                                }
                            }
                        }
                        helper("Your current DIY experience.")
                    }

                    // AR (locked until project exists)
                    if let _ = projectId {
                        tappableRow(
                            icon: "viewfinder.rectangular",
                            title: "Add AR Scan Accuracy",
                            subtitle: "Improve measurements with Room Scan",
                            enabled: true
                        ) {
                            // present your AR sheet here (you already have that view)
                            alert("AR sheet not wired in this file. Hook up your AR view here.")
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

                    // Room photo block
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
                                actionRow(
                                    systemName: "photo.on.rectangle",
                                    title: "Add a room photo"
                                ) {
                                    isShowingLibrary = true
                                }
                                actionRow(
                                    systemName: "camera.viewfinder",
                                    title: "Take Photo for Measurements"
                                ) {
                                    isShowingCamera = true
                                }
                            }
                        }
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
            .disabled(isLoading)
            .overlay {
                if isLoading {
                    ProgressView()
                        .scaleEffect(1.2)
                        .tint(.white)
                }
            }
        }
        // Camera
        .sheet(isPresented: $isShowingCamera) {
            ImagePicker(sourceType: .camera) { ui in
                guard let ui = ui else { return }
                selectedUIImage = ui
            }
            .ignoresSafeArea()
        }
        // Photo Library
        .sheet(isPresented: $isShowingLibrary) {
            ImagePicker(sourceType: .photoLibrary) { ui in
                guard let ui = ui else { return }
                selectedUIImage = ui
            }
            .ignoresSafeArea()
        }
        .alert(alertMessage, isPresented: $showAlert) {
            Button("OK", role: .cancel) { }
        }
    }

    // MARK: - Sections

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                Button {
                    dismiss()
                } label: {
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

    private func sectionCard(@ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            content()
        }
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
        .disabled(isLoading)
        .opacity(isLoading ? 0.6 : 1)
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
        .disabled(isLoading)
        .opacity(isLoading ? 0.6 : 1)
    }

    // MARK: - Actions (wire to your service)

    private func createWithPreview() async {
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else {
            return alert("Please enter a project name.")
        }
        guard !goal.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return alert("Please enter a goal/description.")
        }
        guard let ui = selectedUIImage else {
            return alert("Add a room photo to generate the preview.")
        }

        isLoading = true
        defer { isLoading = false }

        do {
            let photoURL = try await ProjectsService.uploadPhoto(ui)
            let id = try await ProjectsService.createProject(
                name: name,
                goal: goal,
                budget: budget.label,
                skill: skill.label,
                photoURL: photoURL
            )
            projectId = id
            alert("Project created. You can now add an AR scan for better accuracy.")
        } catch {
            alert("Failed to create project: \(error.localizedDescription)")
        }
    }

    private func createWithoutPreview() async {
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else {
            return alert("Please enter a project name.")
        }
        guard !goal.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return alert("Please enter a goal/description.")
        }

        isLoading = true
        defer { isLoading = false }

        do {
            let id = try await ProjectsService.createProject(
                name: name,
                goal: goal,
                budget: budget.label,
                skill: skill.label,
                photoURL: nil
            )
            projectId = id
            alert("Project created. You can now add an AR scan for better accuracy.")
        } catch {
            alert("Failed to create project: \(error.localizedDescription)")
        }
    }

    private func alert(_ text: String) {
        alertMessage = text
        showAlert = true
    }
}
