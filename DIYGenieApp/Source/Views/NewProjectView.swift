import SwiftUI

// MARK: - Simple enums you can map to your schema
enum BudgetTier: String, CaseIterable, Identifiable { case low="$", mid="$$", high="$$$"; var id: String { rawValue } }
enum SkillLevel: String, CaseIterable, Identifiable { case beginner, intermediate, advanced; var id: String { rawValue } }

struct NewProjectView: View {
    // Data
    @State private var name: String = ""
    @State private var goal: String = ""
    @State private var budget: BudgetTier = .mid
    @State private var skill: SkillLevel = .intermediate

    // Photo / AR
    @State private var showingPicker = false
    @State private var showingCamera = false
    @State private var capturedImage: UIImage?
    @State private var projectId: String?     // set after create succeeds

    // UI
    @Environment(\.dismiss) private var dismiss
    @State private var isLoading = false
    @State private var alertMessage: String?
    
    /// Plug your network call here (return the new project id). If not set, we “fake-create”.
    var onCreateProject: ((_ name: String, _ goal: String, _ budget: BudgetTier, _ skill: SkillLevel, _ image: UIImage?) async throws -> String)?

    var body: some View {
        ZStack {
            // Background gradient (uses assets with fallbacks)
            LinearGradient(
                colors: [.bgStart, .bgEnd],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ).ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    header

                    sectionCard {
                        sectionLabel("Project name")
                        TextField("e.g. Floating Shelves", text: $name)
                            .textFieldStyle(.plain)
                            .foregroundColor(.textPrimary)
                            .padding(14)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(Color.white.opacity(0.06))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(Color.surfaceStroke, lineWidth: 1)
                            )
                            .submitLabel(.done)
                    }

                    sectionCard {
                        sectionLabel("Goal / Description")
                        ZStack(alignment: .topLeading) {
                            TextEditor(text: $goal)
                                .frame(minHeight: 120)
                                .foregroundColor(.textPrimary)
                                .padding(10)
                                .background(Color.clear)
                                .scrollContentBackground(.hidden)
                            if goal.isEmpty {
                                Text("Describe what you'd like to build…")
                                    .foregroundColor(.textSecondary.opacity(0.7))
                                    .padding(.top, 16)
                                    .padding(.leading, 16)
                            }
                        }
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color.white.opacity(0.06))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Color.surfaceStroke, lineWidth: 1)
                        )
                    }

                    sectionCard {
                        sectionLabel("Budget")
                        pillSelector(
                            items: BudgetTier.allCases,
                            selection: $budget,
                            title: { $0.rawValue }
                        )
                        footnote("Your project budget range.")
                    }

                    sectionCard {
                        sectionLabel("Skill level")
                        pillSelector(
                            items: SkillLevel.allCases,
                            selection: $skill,
                            title: { title(for: $0) }
                        )
                        footnote("Your current DIY experience.")
                    }

                    sectionCard {
                        sectionLabel("AR & Photo")
                        if let img = capturedImage {
                            photoCard(image: img)
                            retakeRow
                            arRow(enabled: projectId != nil) // show only after we have a project id
                        } else {
                            Button {
                                showingPicker = true
                            } label: {
                                row(icon: "photo.on.rectangle", title: "Add a room photo")
                            }
                            Button {
                                showingCamera = true
                            } label: {
                                row(icon: "camera.aperture", title: "Take Photo for Measurements")
                            }
                            footnote("Add a photo to enable AR scan accuracy.")
                        }
                    }

                    primaryCTA
                    secondaryCTA
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 40)
            }
        }
        .preferredColorScheme(.dark)
        .tint(.accent)
        .alert(alertMessage ?? "", isPresented: .constant(alertMessage != nil)) {
            Button("OK") { alertMessage = nil }
        }
        // Photo library
        .sheet(isPresented: $showingPicker) {
            ImagePicker(sourceType: .photoLibrary) { img in
                guard let img = img else { return }
                Task { await handleNewImage(img) }
            }
            .ignoresSafeArea()
        }
        // Camera
        .sheet(isPresented: $showingCamera) {
            ImagePicker(sourceType: .camera) { img in
                guard let img = img else { return }
                Task { await handleNewImage(img) }
            }
            .ignoresSafeArea()
        }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(Color.textPrimary)
                }
            }
        }
    }
}

// MARK: - Actions
private extension NewProjectView {
    func handleNewImage(_ img: UIImage) async {
        capturedImage = img
        // If we don’t have a project yet, create it now so AR can attach to an id
        if projectId == nil {
            await createProjectIfNeeded()
        }
    }

    func createProjectIfNeeded() async {
        guard projectId == nil else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            if let hook = onCreateProject {
                let id = try await hook(name, goal, budget, skill, capturedImage)
                projectId = id
            } else {
                // Safe fallback so UI flow works while you wire your backend
                projectId = UUID().uuidString
            }
        } catch {
            alertMessage = "Couldn’t create project: \(error.localizedDescription)"
        }
    }
}

// MARK: - UI bits
private extension NewProjectView {
    var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("New Project")
                .font(.system(size: 36, weight: .bold))
                .foregroundStyle(Color.textPrimary)
            Text("Get everything you need to bring your next DIY idea to life.")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(Color.textSecondary)
        }
        .padding(.top, 8)
    }

    func sectionCard<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            content()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.surfaceStroke, lineWidth: 1)
        )
    }

    func sectionLabel(_ title: String) -> some View {
        Text(title.uppercased())
            .font(.footnote.weight(.semibold))
            .foregroundStyle(Color.textSecondary)
    }

    func footnote(_ text: String) -> some View {
        Text(text)
            .font(.footnote)
            .foregroundStyle(Color.textSecondary)
    }

    func title(for skill: SkillLevel) -> String {
        switch skill {
        case .beginner: return "Beginner"
        case .intermediate: return "Intermediate"
        case .advanced: return "Advanced"
        }
    }

    func row(icon: String, title: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .imageScale(.medium)
            Text(title)
                .font(.headline)
        }
        .foregroundStyle(Color.textPrimary)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 14)
        .padding(.horizontal, 12)
        .background(RoundedRectangle(cornerRadius: 14).fill(Color.white.opacity(0.06)))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.surfaceStroke, lineWidth: 1))
    }

    func photoCard(image: UIImage) -> some View {
        HStack(alignment: .center, spacing: 14) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: 110, height: 110)
                .clipped()
                .cornerRadius(12)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.surfaceStroke, lineWidth: 1))

            VStack(alignment: .leading, spacing: 6) {
                Text("Photo attached")
                    .font(.headline)
                    .foregroundStyle(Color.textPrimary)
                Text("Use AR or retake for measurement accuracy.")
                    .font(.subheadline)
                    .foregroundStyle(Color.textSecondary)
            }
            Spacer()
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 14).fill(Color.white.opacity(0.06)))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.surfaceStroke, lineWidth: 1))
    }

    var retakeRow: some View {
        Button {
            showingCamera = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "arrow.triangle.2.circlepath.camera")
                Text("Retake photo")
            }
            .font(.headline)
            .foregroundStyle(Color.accent)
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
    }

    func arRow(enabled: Bool) -> some View {
        Button {
            // Present your AR sheet here (you already wired ARRoomPlanSheet)
            // Guard on projectId & capturedImage upstream in your call site if needed.
        } label: {
            HStack {
                Image(systemName: "viewfinder.rectangular")
                Text("Add AR Scan Accuracy")
                Spacer()
                Text(enabled ? "" : "Create the project first")
                    .font(.footnote)
                    .foregroundStyle(Color.textSecondary)
            }
            .font(.headline)
        }
        .disabled(!enabled)
        .opacity(enabled ? 1 : 0.5)
        .foregroundStyle(Color.textPrimary)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 14)
        .padding(.horizontal, 12)
        .background(RoundedRectangle(cornerRadius: 14).fill(Color.white.opacity(0.06)))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.surfaceStroke, lineWidth: 1))
    }

    var primaryCTA: some View {
        Button {
            Task { await createProjectIfNeeded() }
        } label: {
            Text(isLoading ? "Creating…" : "Generate AI Plan + Preview")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(colors: [.accent, .accentSoft], startPoint: .leading, endPoint: .trailing)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                )
                .foregroundStyle(Color.textPrimary)
        }
        .disabled(isLoading)
        .padding(.top, 8)
    }

    var secondaryCTA: some View {
        Button {
            // text-only plan path; still ensure project exists
            Task { await createProjectIfNeeded() }
        } label: {
            Text("Create Plan Only (no preview)")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.white.opacity(0.06))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.surfaceStroke, lineWidth: 1)
                )
                .foregroundStyle(Color.textPrimary)
        }
    }

    // Reusable segmented pills
    func pillSelector<T: Identifiable & Equatable>(
        items: [T],
        selection: Binding<T>,
        title: @escaping (T) -> String
    ) -> some View {
        HStack(spacing: 12) {
            ForEach(items) { item in
                let isOn = selection.wrappedValue == item
                Button {
                    selection.wrappedValue = item
                } label: {
                    Text(title(item))
                        .font(.headline)
                        .foregroundStyle(isOn ? Color.textPrimary : Color.textPrimary.opacity(0.9))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(isOn ? Color.white.opacity(0.10) : Color.white.opacity(0.05))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(isOn ? Color.accent : Color.surfaceStroke, lineWidth: 1)
                        )
                }
            }
        }
    }
}
