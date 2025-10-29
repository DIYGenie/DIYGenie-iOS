import SwiftUI
import PhotosUI

// MARK: - UI enums
enum Budget: String, CaseIterable, Identifiable {
    case one = "$", two = "$$", three = "$$$"
    var id: String { rawValue }
    var label: String { rawValue }
}

enum Skill: String, CaseIterable, Identifiable {
    case beginner, intermediate, advanced
    var id: String { rawValue }
    var label: String {
        switch self {
        case .beginner: return "Beginner"
        case .intermediate: return "Intermediate"
        case .advanced: return "Advanced"
        }
    }
}

// MARK: - Color / Style
extension Color {
    static let geniePurpleDarkTop = Color(red: 28/255, green: 26/255, blue: 40/255)     // near-black violet
    static let geniePurpleDarkBottom = Color(red: 58/255, green: 35/255, blue: 110/255)  // deep purple
    static let genieAccent = Color(red: 146/255, green: 86/255, blue: 255/255)           // darker purple (less pink)
    static let genieAccent2 = Color(red: 115/255, green: 73/255, blue: 224/255)
    static let actionGreen = Color(red: 52/255, green: 199/255, blue: 89/255)            // Apple green
}

struct NewProjectView: View {
    @Environment(\.dismiss) private var dismiss

    // Form
    @State private var name: String = ""
    @State private var goal: String = ""
    @State private var budget: Budget = .two
    @State private var skill: Skill = .intermediate

    // Media + measure
    @State private var showingImagePicker = false
    @State private var selectedImage: UIImage?
    @State private var showingMeasureView = false
    @State private var measuredWidthInches: Double = 0
    @State private var measuredHeightInches: Double = 0

    // UI
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @FocusState private var isFocused: Bool

    // Flags for pipelines
    @State private var isSaving: Bool = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [.geniePurpleDarkTop, .geniePurpleDarkBottom],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {

                    // Back
                    HStack {
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white.opacity(0.9))
                        }
                        Spacer()
                    }
                    .padding(.top, 8)

                    // Title
                    Text("New Project")
                        .font(.system(size: 34, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.top, 4)

                    Text("Plan your next project like a pro 🔧")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(.white.opacity(0.7))

                    // Project Name
                    card {
                        VStack(alignment: .leading, spacing: 8) {
                            label("Project Name")
                            TextField("e.g. Floating Shelves", text: $name)
                                .textInputAutocapitalization(.words)
                                .submitLabel(.done)
                                .focused($isFocused)
                                .onSubmit { isFocused = false }
                                .padding(12)
                                .background(.black.opacity(0.2))
                                .cornerRadius(12)
                                .foregroundColor(.white)
                        }
                    }

                    // Description
                    card {
                        VStack(alignment: .leading, spacing: 8) {
                            label("Goal / Description")
                            ZStack(alignment: .topLeading) {
                                TextEditor(text: $goal)
                                    .frame(minHeight: 120)
                                    .padding(8)
                                    .background(.black.opacity(0.2))
                                    .cornerRadius(12)
                                    .foregroundColor(.white)
                                    .focused($isFocused)

                                if goal.isEmpty {
                                    Text("Describe what you'd like to build…")
                                        .foregroundColor(.white.opacity(0.35))
                                        .padding(.top, 16)
                                        .padding(.leading, 14)
                                }
                            }
                            Text("\(max(0, 10 - goal.count)) more characters to enable actions")
                                .font(.footnote)
                                .foregroundColor(.white.opacity(0.45))
                                .opacity(goal.count < 10 ? 1 : 0)
                        }
                    }

                    // Budget
                    card {
                        VStack(alignment: .leading, spacing: 10) {
                            label("Budget")
                            Picker("", selection: $budget) {
                                ForEach(Budget.allCases) { tier in
                                    Text(tier.label).tag(tier)
                                }
                            }
                            .pickerStyle(.menu)
                            .tint(.white)
                            Text("Choose your price range.")
                                .font(.footnote)
                                .foregroundColor(.white.opacity(0.45))
                        }
                    }

                    // Skill
                    card {
                        VStack(alignment: .leading, spacing: 10) {
                            label("Skill Level")
                            Picker("", selection: $skill) {
                                ForEach(Skill.allCases) { lvl in
                                    Text(lvl.label).tag(lvl)
                                }
                            }
                            .pickerStyle(.menu)
                            .tint(.white)
                            Text(skillHelpText)
                                .font(.footnote)
                                .foregroundColor(.white.opacity(0.45))
                        }
                    }

                    // Capture Button (photo + measure)
                    Button(action: {
                        isFocused = false
                        showingImagePicker = true
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: "viewfinder")
                                .font(.system(size: 20, weight: .semibold))
                            Text(selectedImage == nil
                                 ? "Take Photo & Measure Room"
                                 : "Retake Photo & Re-Measure")
                                .font(.system(size: 18, weight: .semibold))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(colors: [.genieAccent2, .genieAccent],
                                           startPoint: .leading, endPoint: .trailing)
                        )
                        .foregroundColor(.white)
                        .cornerRadius(16)
                        .shadow(color: .black.opacity(0.25), radius: 12, x: 0, y: 8)
                    }
                    .padding(.top, 4)

                    // Thumbnail + dims (if available)
                    if let img = selectedImage, (measuredWidthInches > 0 && measuredHeightInches > 0) {
                        HStack(spacing: 12) {
                            Image(uiImage: img)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 64, height: 64)
                                .clipped()
                                .cornerRadius(12)

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Room photo saved")
                                    .foregroundColor(.white)
                                    .font(.subheadline).bold()
                                Text("Measured: \(formatted(measuredWidthInches))\" × \(formatted(measuredHeightInches))\"")
                                    .foregroundColor(.white.opacity(0.8))
                                    .font(.footnote)
                            }
                            Spacer()
                        }
                        .padding(.top, 4)
                    }

                    // Action CTAs (only after photo + measurement exist)
                    if canShowActions {
                        VStack(spacing: 12) {
                            // Pro/Casual: Plan + Preview
                            Button {
                                runPipeline(wantsPreview: true)
                            } label: {
                                Text("Generate AI Plan + Preview")
                                    .font(.system(size: 18, weight: .bold))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(
                                        LinearGradient(colors: [.genieAccent2, .genieAccent],
                                                       startPoint: .leading, endPoint: .trailing)
                                    )
                                    .foregroundColor(.white)
                                    .cornerRadius(16)
                                    .shadow(color: .black.opacity(0.25), radius: 12, x: 0, y: 8)
                            }
                            .disabled(isSaving)

                            // Free: Plan only
                            Button {
                                runPipeline(wantsPreview: false)
                            } label: {
                                Text("Create Plan Only (No Preview)")
                                    .font(.system(size: 17, weight: .semibold))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 15)
                                    .background(Color.white.opacity(0.08))
                                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.18), lineWidth: 1))
                                    .foregroundColor(.white)
                                    .cornerRadius(14)
                            }
                            .disabled(isSaving)
                        }
                        .padding(.top, 8)
                    }

                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
            .onTapGesture { isFocused = false } // dismiss keyboard
        }
        // Image picker → after select, open measurement
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker { image in
                if let image = image {
                    self.selectedImage = image
                    // auto-open measurement overlay after slight delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                        self.showingMeasureView = true
                    }
                }
            }
            .preferredColorScheme(.dark)
        }
        // Rect measurement overlay
        .sheet(isPresented: $showingMeasureView) {
            // IMPORTANT: your MeasureOverlayView must expose `init(onComplete: @escaping (Double, Double)->Void)`
            MeasureOverlayView { widthIn, heightIn in
                self.measuredWidthInches = max(0, widthIn)
                self.measuredHeightInches = max(0, heightIn)
                self.showingMeasureView = false
            }
            .preferredColorScheme(.dark)
        }
        .alert("Upload Status", isPresented: $showingAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
    }

    // MARK: - Derived State
    private var canShowActions: Bool {
        let baseOk = !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
                     goal.trimmingCharacters(in: .whitespacesAndNewlines).count >= 10
        let mediaOk = (selectedImage != nil) && measuredWidthInches > 0 && measuredHeightInches > 0
        return baseOk && mediaOk
    }

    private var skillHelpText: String {
        switch skill {
        case .beginner: return "Simple tools and steps."
        case .intermediate: return "Moderate tools and precision."
        case .advanced: return "Complex builds and advanced tools."
        }
    }

    // MARK: - Actions
    private func runPipeline(wantsPreview: Bool) {
        guard canShowActions, let image = selectedImage else { return }
        isSaving = true

        Task {
            do {
                // 1) Upload image to Supabase (uploads bucket)
                //    Adjust to your existing uploader signature if needed.
                //    Expecting it returns a public path or URL.
                let uploader = SupabaseUploader()
                let path = try await uploader.uploadImage(image, toFolder: "uploads")

                // 2) Create project via your backend service
                //    Adjust to your ProjectsService as needed.
                let projectId = try await ProjectsService.shared.createProject(
                    name: name,
                    goal: goal,
                    budget: budget.label,
                    skillLevel: skill.label,
                    imagePath: path,
                    measuredWidthInches: measuredWidthInches,
                    measuredHeightInches: measuredHeightInches,
                    wantsPreview: wantsPreview
                )

                // 3) Navigate to Project Details
                //    If you use a NavigationPath or tab routing, call it here.
                //    For now, just show a toast and pop; your list should refresh.
                alertMessage = "Project created!"
                showingAlert = true
                isSaving = false
                dismiss()

                // TODO: If you prefer a push, replace dismiss() with a route
                // to ProjectDetailsView(projectId: projectId)

            } catch {
                isSaving = false
                alertMessage = "Failed to create project: \(error.localizedDescription)"
                showingAlert = true
            }
        }
    }

    // MARK: - Helpers
    private func card<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        VStack { content() }
            .padding(16)
            .background(Color.white.opacity(0.07))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.16), lineWidth: 1))
            .cornerRadius(16)
    }

    private func label(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 15, weight: .semibold))
            .foregroundColor(.white.opacity(0.9))
    }

    private func formatted(_ inches: Double) -> String {
        let n = NSNumber(value: inches)
        let f = NumberFormatter()
        f.maximumFractionDigits = 1
        f.minimumFractionDigits = 0
        return f.string(from: n) ?? String(format: "%.1f", inches)
    }
}
