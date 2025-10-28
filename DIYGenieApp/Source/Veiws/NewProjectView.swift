import SwiftUI
import PhotosUI

struct NewProjectView: View {
    @Environment(\.presentationMode) var presentationMode

    // MARK: - Form State
    @State private var name = ""
    @State private var goal = ""
    @State private var budgetTier: Budget = .two
    @State private var skill: Skill = .intermediate
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var roomScanURL: URL?
    @State private var showScanSaved = false
    @State private var isShowingARScan = false

    // MARK: - Validation
    private var isFormValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty &&
        goal.count >= 10
    }

    // MARK: - Theme
    private let accent = Color(red: 98/255, green: 70/255, blue: 255/255)

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
                    // Header
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

                    // Project Details
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Project Name")
                            .font(.system(.subheadline, design: .rounded, weight: .semibold))
                        TextField("Enter project name", text: $name)
                            .padding(10)
                            .background(Color(.systemGray6))
                            .cornerRadius(10)

                        Text("Goal / Description")
                            .font(.system(.subheadline, design: .rounded, weight: .semibold))
                        TextEditor(text: $goal)
                            .frame(minHeight: 100)
                            .padding(10)
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(goal.count < 10 ? Color.red.opacity(0.25) : Color.gray.opacity(0.2), lineWidth: 1)
                            )
                            .scrollContentBackground(.hidden)

                        Text("\(goal.count)/10 characters minimum")
                            .font(.caption2)
                            .foregroundColor(goal.count < 10 ? .red.opacity(0.6) : .gray.opacity(0.6))
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(14)
                    .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)

                    // Budget Dropdown
                    dropdownCard(
                        title: "Budget",
                        hint: "Choose your price range.",
                        selectionText: budgetTier.description,
                        options: [
                            ("Budget-Friendly ($)", Budget.one),
                            ("Mid-Range ($$)", Budget.two),
                            ("Premium ($$$)", Budget.three)
                        ],
                        currentSelection: $budgetTier
                    )

                    // Skill Level Dropdown
                    dropdownCard(
                        title: "Skill Level",
                        hint: "Select your experience level.",
                        selectionText: skill.label,
                        options: [
                            ("Beginner", Skill.beginner),
                            ("Intermediate", Skill.intermediate),
                            ("Advanced", Skill.advanced)
                        ],
                        currentSelection: $skill
                    )

                    // Room Scan / Upload
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

                    // Action Buttons
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

    // MARK: - Helper Views
    private func dropdownCard<T: Identifiable>(
        title: String,
        hint: String,
        selectionText: String,
        options: [(String, T)],
        currentSelection: Binding<T>
    ) -> some View where T: Equatable {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(.subheadline, design: .rounded, weight: .semibold))

            Menu {
                ForEach(options, id: \.1.id) { label, value in
                    Button(label) {
                        currentSelection.wrappedValue = value
                    }
                }
            } label: {
                HStack {
                    Text(selectionText)
                        .foregroundColor(.primary)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
            }

            Text(hint)
                .font(.system(.footnote, design: .rounded))
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(14)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }

    private func generatePlan(withPreview: Bool) {
        print("Generate plan tapped. With preview: \(withPreview)")
    }
}

// MARK: - Enums
enum Budget: String, CaseIterable, Identifiable {
    case one = "$", two = "$$", three = "$$$"
    var id: String { rawValue }
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
