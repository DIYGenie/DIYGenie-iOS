import SwiftUI

// MARK: - NewProjectView

struct NewProjectView: View {
    // Form state
    @State private var name: String = ""
    @State private var goal: String = ""
    @State private var budget: Budget = .mid
    @State private var skill: Skill = .intermediate
    enum BudgetSelection: String, CaseIterable { case $, $$, $$$ }
    enum SkillSelection: String, CaseIterable { case beginner, intermediate, advanced }

    @State private var capturedUIImage: UIImage? = nil

    private let currentUserId = "99198c4b-8470-49e2-895c-75593c5aa181" // from your logs; replace with real session id when wired
    @State private var showingLibrary = false
    @State private var showingCamera = false
    @State private var showingARScanner = false

    // Flow
    @Environment(\.dismiss) private var dismiss
    @State private var isLoading = false
    @State private var alertMessage: String?
    @State private var projectId: UUID? // set after successful create

    var body: some View {
        ZStack {
            // Background
            LinearGradient(colors: [.bgStart, .bgEnd],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {

                    // Header
                    header

                    // Project name
                    SectionCard(title: "Project name") {
                        TextField("e.g. Floating Shelves", text: $name)
                            .textInputAutocapitalization(.words)
                            .foregroundStyle(.textPrimary)
                            .padding(14)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.surfaceStroke.opacity(0.6))
                            )
                    }

                    // Goal / Description
                    SectionCard(title: "Goal / Description",
                                help: "Describe what you'd like to build…") {
                        TextEditor(text: $goal)
                            .frame(minHeight: 140)
                            .scrollContentBackground(.hidden)
                            .foregroundStyle(.textPrimary)
                            .padding(8)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.surfaceStroke.opacity(0.6))
                            )
                    }

                    // Budget
                    SectionCard(title: "Budget",
                                help: "Your project budget range.") {
                        SegmentedPills(selection: $budget,
                                       items: Budget.allCases.map { ($0, $0.title) })
                    }

                    // Skill level
                    SectionCard(title: "Skill level",
                                help: "Your current DIY experience.") {
                        SegmentedPills(selection: $skill,
                                       items: Skill.allCases.map { ($0, $0.title) })
                    }

                    // AR + Photos
                    SectionCard(spacing: 14, title: "Room photo") {
                        if let img = capturedImage {
                            PhotoRow(image: img, onRetake: { showingCamera = true })
                        } else {
                            VStack(spacing: 10) {
                                Button {
                                    showingLibrary = true
                                } label: {
                                    HStack {
                                        Image(systemName: "photo.on.rectangle")
                                        Text("Add a room photo")
                                        Spacer()
                                    }
                                    .foregroundStyle(.textPrimary)
                                    .padding(14)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.surfaceStroke.opacity(0.6))
                                    )
                                }

                                Button {
                                    showingCamera = true
                                } label: {
                                    HStack {
                                        Image(systemName: "camera.viewfinder")
                                        Text("Take Photo for Measurements")
                                        Spacer()
                                    }
                                    .foregroundStyle(.textPrimary)
                                    .padding(14)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.surfaceStroke.opacity(0.6))
                                    )
                                }
                            }
                        }

                        // AR button appears only when photo saved & project exists
                        if projectId != nil, capturedImage != nil {
                            Button {
                                showingARScanner = true
                            } label: {
                                HStack {
                                    Image(systemName: "viewfinder")
                                    Text("Add AR Scan Accuracy")
                                    Spacer()
                                }
                                .foregroundStyle(.textPrimary)
                                .padding(14)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.surfaceStroke.opacity(0.6))
                                )
                            }
                        } else {
                            // Disabled hint row (visible until project created)
                            HStack {
                                Image(systemName: "viewfinder")
                                Text("Add AR Scan Accuracy")
                                Spacer()
                                Text("Create the project first")
                                    .foregroundStyle(.textSecondary)
                            }
                            .foregroundStyle(.textSecondary)
                            .padding(14)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.surfaceStroke.opacity(0.3))
                            )
                        }
                    }

                    // CTAs
                    VStack(spacing: 12) {
                        Button {
                            submit(createPreview: true)
                        } label: {
                            Text("Generate AI Plan + Preview")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(PrimaryCTAStyle())

                        Button {
                            submit(createPreview: false)
                        } label: {
                            Text("Create Plan Only (no preview)")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(SecondaryCTAStyle())
                    }
                    .padding(.top, 4)
                    .padding(.bottom, 40)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }

            if isLoading {
                ProgressView()
                    .progressViewStyle(.circular)
                    .tint(.accent)
                    .scaleEffect(1.2)
            }
        }
        // Photo library
        .sheet(isPresented: $showingLibrary) {
            ImagePicker(sourceType: .photoLibrary) { img in
                Task { await handleNewImage(img) }
            }
            .ignoresSafeArea()
        }
        // Camera
        .sheet(isPresented: $showingCamera) {
            ImagePicker(sourceType: .camera) { img in
                Task { await handleNewImage(img) }
            }
            .ignoresSafeArea()
        }
        
        let projectId = try await ProjectsService.createProject(
            name: name,
            goal: goal,
            budget: BudgetSelection,   // "$", "$$", or "$$$"
            skill: skillSelection,     // "beginner" | "intermediate" | "advanced"
            userId: currentUserId,
            photoURL: nil
        )

        if let img = selectedUIImage {
            let publicURL = try await ProjectsService.uploadPhoto(img)
            try await ProjectsService.attachPhoto(to: projectId, url: publicURL)
        }

        // AR (placeholder if your AR view isn’t wired yet)
        .sheet(isPresented: $showingARScanner) {
            #if canImport(RoomPlan)
            // Replace with your ARRoomPlan sheet when ready
            Text("AR Scanner goes here")
                .foregroundStyle(.textPrimary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(LinearGradient(colors: [.bgStart, .bgEnd],
                                           startPoint: .topLeading, endPoint: .bottomTrailing))
                .ignoresSafeArea()
            #else
            Text("RoomPlan not available on this device.")
                .padding()
            #endif
        }
        .alert("Oops", isPresented: .init(
            get: { alertMessage != nil },
            set: { if !$0 { alertMessage = nil } }
        )) { } message: {
            Text(alertMessage ?? "")
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.textPrimary)
                    .padding(10)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.surfaceStroke)
                            .fill(Color.black.opacity(0.15))
                    )
            }
            .buttonStyle(.plain)

            Text("New Project")
                .font(.system(size: 38, weight: .bold))
                .foregroundStyle(.textPrimary)

            Text("Get everything you need to bring your next DIY idea to life.")
                .font(.callout)
                .foregroundStyle(.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 4)
    }

    // MARK: - Actions

    private func submit(createPreview: Bool) {
        Task {
            guard !isLoading else { return }
            guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                alertMessage = "Please enter a project name."
                return
            }
            guard !goal.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                alertMessage = "Please describe your goal."
                return
            }
            isLoading = true
            defer { isLoading = false }

            // Ensure project exists
            if projectId == nil {
                do {
                    let newId = try await createProject(
                        name: name,
                        goal: goal,
                        budget: budget.rawValue,
                        skill: skill.rawValue
                    )
                    projectId = newId
                } catch {
                    alertMessage = "Could not create project: \(error.localizedDescription)"
                    return
                }
            }

            // Continue your flow (navigate to details, call preview, etc.)
            // TODO: hook into your existing navigation or service
        }
    }

    private func handleNewImage(_ img: UIImage?) async {
        guard let img else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            // 1) Upload photo (Supabase storage or your API)
            let photoURL = try await uploadPhoto(img)

            // 2) Create project if needed (required for AR button)
            if projectId == nil {
                let newId = try await createProject(
                    name: name.isEmpty ? "Untitled" : name,
                    goal: goal,
                    budget: budget.rawValue,
                    skill: skill.rawValue,
                    photoURL: photoURL
                )
                projectId = newId
            } else {
                // Optionally: attach/patch photo to existing project
                try await attachPhoto(to: projectId!, url: photoURL)
            }

            capturedImage = img
        } catch {
            alertMessage = "Upload failed: \(error.localizedDescription)"
        }
    }

    // MARK: - Service hooks (replace with your real implementations)

    private func createProject(name: String,
                               goal: String,
                               budget: String,
                               skill: String,
                               photoURL: URL? = nil) async throws -> UUID {
        // TODO: call your APIClient / Supabase (POST /projects)
        // Return the created UUID from backend.
        // Temporary local UUID so UI can proceed:
        return UUID()
    }

    private func uploadPhoto(_ image: UIImage) async throws -> URL {
        // TODO: upload to Supabase Storage or your webhook.
        // Return a URL for the uploaded image.
        // Temporary local file URL:
        let tmp = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("room-\(UUID().uuidString).jpg")
        if let data = image.jpegData(compressionQuality: 0.9) {
            try data.write(to: tmp)
        }
        return tmp
    }

    private func attachPhoto(to projectId: UUID, url: URL) async throws {
        // TODO: PATCH project with photo URL
    }
}

// MARK: - Models

private enum Budget: String, CaseIterable, Equatable, Identifiable {
    case low = "$", mid = "$$", high = "$$$"
    var id: String { rawValue }
    var title: String { rawValue }
}

private enum Skill: String, CaseIterable, Equatable, Identifiable {
    case beginner, intermediate, advanced
    var id: String { rawValue }
    var title: String {
        switch self {
        case .beginner: "Beginner"
        case .intermediate: "Intermediate"
        case .advanced: "Advanced"
        }
    }
}

// MARK: - Reusable UI

private struct SectionCard<Content: View>: View {
    var spacing: CGFloat = 12
    let title: String
    var help: String? = nil
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: spacing) {
            Text(title.uppercased())
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.textSecondary)
                .kerning(0.5)

            content

            if let help {
                Text(help)
                    .font(.footnote)
                    .foregroundStyle(.textSecondary)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.surface, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.surfaceStroke, lineWidth: 1))
    }
}

private struct SegmentedPills<T: Hashable & Identifiable & Equatable>: View {
    @Binding var selection: T
    let items: [(T, String)]

    var body: some View {
        HStack(spacing: 10) {
            ForEach(items, id: \.0.id) { (item, title) in
                Button {
                    selection = item
                } label: {
                    Text(title)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(selection == item ? Color.white.opacity(0.08) : Color.clear)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.surfaceStroke, lineWidth: 1)
                )
                .foregroundStyle(.textPrimary)
            }
        }
    }
}

private struct PhotoRow: View {
    let image: UIImage
    let onRetake: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: 96, height: 96)
                .clipShape(RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 6) {
                Text("Photo attached").foregroundStyle(.textPrimary)
                Button("Retake") { onRetake() }
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.accent)
            }
            Spacer()
        }
    }
}

private struct PrimaryCTAStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color.accent)
            )
            .foregroundStyle(.white)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
    }
}

private struct SecondaryCTAStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color.black.opacity(0.15))
                    .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.surfaceStroke))
            )
            .foregroundStyle(.textPrimary)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
    }
}
