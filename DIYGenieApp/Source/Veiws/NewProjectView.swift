import SwiftUI

// MARK: - Local enums (lightweight, no external deps)
enum Budget: String, CaseIterable {
    case one = "$", two = "$$", three = "$$$"
    var label: String { rawValue }
}

enum Skill: String, CaseIterable {
    case beginner, intermediate, advanced
    var label: String { rawValue.capitalized }
}

struct NewProjectView: View {
    @Environment(\.dismiss) private var dismiss

    // MARK: - Form State
    @State private var name: String = ""
    @State private var goal: String = ""
    @State private var budgetTier: Budget = .two
    @State private var skill: Skill = .intermediate

    // MARK: - Room Scan
    @State private var isShowingARScan = false
    @State private var roomScanURL: URL?
    @State private var showScanSavedMessage = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Project Info") {
                    TextField("Project Name", text: $name)
                        .textInputAutocapitalization(.words)
                    TextField("Goal (e.g., repaint walls, add shelves)", text: $goal)

                    Picker("Budget", selection: $budgetTier) {
                        ForEach(Budget.allCases, id: \.self) { tier in
                            Text(tier.label).tag(tier)
                        }
                    }

                    Picker("Skill Level", selection: $skill) {
                        ForEach(Skill.allCases, id: \.self) { level in
                            Text(level.label).tag(level)
                        }
                    }
                }

                Section("Room Scan") {
                    Button {
                        isShowingARScan = true
                        showScanSavedMessage = false
                    } label: {
                        Label("Start Room Scan", systemImage: "camera.viewfinder")
                    }

                    if showScanSavedMessage, roomScanURL != nil {
                        Label("Room scan saved ✅", systemImage: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    }
                }

                Section {
                    Button("Save Project") {
                        saveProject()
                    }
                    .disabled(name.isEmpty || goal.isEmpty)
                }
            }
            .navigationTitle("New Project")
            .sheet(isPresented: $isShowingARScan) {
                // Match your ARScanView signature that returns URL? only on finish
                ARScanView { url in
                    // Finish
                    roomScanURL = url
                    showScanSavedMessage = (url != nil)
                    isShowingARScan = false
                }
                // While scanning, keep the sheet up (prevents accidental swipe-down)
                .interactiveDismissDisabled(true)
            }
        }
    }

    // MARK: - Save Logic (wire this to ProjectsService next)
    private func saveProject() {
        // TODO: send name, goal, budgetTier.rawValue, skill.rawValue, and roomScanURL (if present)
        // to your ProjectsService backend.
        dismiss()
    }
}
