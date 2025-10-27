import SwiftUI
import PhotosUI

struct NewProjectView: View {
    @Environment(\.presentationMode) var presentationMode

    // MARK: - Form State
    @State private var name = ""
    @State private var goal = ""
    @State private var budgetTier: Budget = .two
    @State private var skill: Skill = .intermediate

    // MARK: - Media / AR
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var roomScanURL: URL?
    @State private var showScanSaved = false
    @State private var isShowingARScan = false

    // MARK: - Validation
    private var isFormValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty &&
        !goal.trimmingCharacters(in: .whitespaces).isEmpty
    }

    // MARK: - Theme
    private let accent = Color(red: 113/255, green: 66/255, blue: 255/255)

    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [Color(.systemGray6), Color.white]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    // MARK: - Header
                    HStack {
                        Button(action: { presentationMode.wrappedValue.dismiss() }) {
                            Image(systemName: "chevron.left")
                                .font(.title3.weight(.semibold))
                                .foregroundColor(accent)
                        }
                        Spacer()
                        Text("New Project")
                            .font(.system(.title2, design: .rounded, weight: .bold))
                            .foregroundColor(.primary)
                        Spacer()
                        Image(systemName: "chevron.left").opacity(0)
                    }
                    .padding(.top, 16)

                    Text("Plan your next project like a pro 🔨")
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundColor(.secondary)

                    // MARK: - Project Details
                    VStack(alignment: .leading, spacing: 16) {
                        Group {
                            Text("Project Name")
                                .font(.system(.subheadline, design: .rounded, weight: .semibold))
                            TextField("Enter name", text: $name)
                                .padding(10)
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                                .submitLabel(.next)

                            Text("Goal / Description")
                                .font(.system(.subheadline, design: .rounded, weight: .semibold))
                            TextField("What are you building?", text: $goal)
                                .padding(10)
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                                .submitLabel(.done)
                                .onSubmit { hideKeyboard() }
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(14)
                    .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)

                    // MARK: - Budget Dropdown
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Budget")
                            .font(.system(.subheadline, design: .rounded, weight: .semibold))

                        Menu {
                            Button("Budget-Friendly ($)") { budgetTier = .one }
                            Button("Mid-Range ($$)") { budgetTier = .two }
                            Button("Premium ($$$)") { budgetTier = .three }
                        } label: {
                            HStack {
                                Text(budgetTier.description)
                                    .foregroundColor(.primary)
                                Spacer()
                                Image(systemName: "chevron.down")
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                        }

                        Text("Choose your price range.")
                            .font(.system(.footnote, design: .rounded))
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(14)
                    .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)

                    // MARK: - Skill Level Dropdown
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Skill Level")
                            .font(.system(.subheadline, design: .rounded, weight: .semibold))

                        Menu {
                            Button("Beginner") { skill = .beginner }
                            Button("Intermediate") { skill = .intermediate }
                            Button("Advanced") { skill = .advanced }
                        } label: {
                            HStack {
                                Text(skill.label)
                                    .foregroundColor(.primary)
                                Spacer()
                                Image(systemName: "chevron.down")
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                        }

                        Text("Select your experience level.")
                            .font(.system(.footnote, design: .rounded))
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(14)
                    .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)

                    // MARK: - Room Setup
                    VStack(spacing: 12) {
                        Button {
                            isShowingARScan = true
                        } label: {
                            Label("Scan Room (AR)", systemImage: "camera.viewfinder")
                                .font(.system(.headline, design: .rounded))
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(accent)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }

                        PhotosPicker(selection: $selectedPhoto, matching: .images) {
                            Label("Upload Photo", systemImage: "photo.on.rectangle.angled")
                                .font(.system(.headline, design: .rounded))
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.gray.opacity(0.15))
                                .foregroundColor(.primary)
                                .cornerRadius(10)
                        }

                        if showScanSaved, roomScanURL != nil {
                            Label("Room scan saved ✅", systemImage: "checkmark.circle.fill")
                                .foregroundColor(.green)
                                .font(.system(.subheadline, design: .rounded))
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(14)
                    .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)

                    // MARK: - Action Buttons
                    VStack(spacing: 12) {
                        Button {
                            generatePlan(withPreview: true)
                        } label: {
                            Label("Generate AI Plan + Preview", systemImage: "bolt.fill")
                                .font(.system(.headline, design: .rounded))
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(isFormValid ? accent : accent.opacity(0.3))
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                        .disabled(!isFormValid)

                        Button {
                            generatePlan(withPreview: false)
                        } label: {
                            Label("Create Plan Only (No Preview)", systemImage: "list.bullet.clipboard")
                                .font(.system(.headline, design: .rounded))
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(isFormValid ? Color.gray : Color.gray.opacity(0.3))
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                        .disabled(!isFormValid)
                    }
                    .padding(.bottom, 40)
                }
                .padding(.horizontal, 20)
            }
            .onTapGesture { hideKeyboard() }
        }
        .sheet(isPresented: $isShowingARScan) {
            ARScanView { url in
                roomScanURL = url
                showScanSaved = (url != nil)
                isShowingARScan = false
            }
        }
    }

    private func generatePlan(withPreview: Bool) {
        print("Generate plan tapped. With preview: \(withPreview)")
    }
}

// MARK: - Enums
enum Budget: String, CaseIterable, Identifiable {
    case one = "$", two = "$$", three = "$$$"
    var id: String { rawValue }
    var label: String { rawValue }
    var description: String {
        switch self {
        case .one: return "Budget-Friendly ($)"
        case .two: return "Mid-Range ($$)"
        case .three: return "Premium ($$$)"
        }
    }
}

enum Skill: String, CaseIterable, Identifiable {
    case beginner, intermediate, advanced
    var id: String { rawValue }
    var label: String { rawValue.capitalized }
}

// MARK: - Keyboard Dismiss Helper
extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),
                                        to: nil, from: nil, for: nil)
    }
}
