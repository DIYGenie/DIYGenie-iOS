//
//  NewProjectView.swift
//  DIYGenieApp
//

import SwiftUI
import PhotosUI

struct NewProjectView: View {
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - State
    @State private var name: String = ""
    @State private var goal: String = ""
    @State private var selectedImage: UIImage? = nil
    @State private var showImagePicker = false
    @State private var isSaving = false

    // MARK: - Enums
    enum Budget: String, CaseIterable, Identifiable {
        case one = "$", two = "$$", three = "$$$"
        var id: String { rawValue }
        var label: String { rawValue }
    }

    enum Skill: String, CaseIterable, Identifiable {
        case beginner, intermediate, advanced
        var id: String { rawValue }
        var label: String { rawValue.capitalized }
    }

    @State private var budget: Budget = .two
    @State private var skill: Skill = .intermediate

    // MARK: - Body
    var body: some View {
        NavigationView {
            Form {
                Section("Details") {
                    TextField("Project name", text: $name)
                    TextField("Goal / Description", text: $goal)
                    Picker("Budget", selection: $budget) {
                        ForEach(Budget.allCases) { tier in
                            Text(tier.label).tag(tier)
                        }
                    }
                    Picker("Skill level", selection: $skill) {
                        ForEach(Skill.allCases) { s in
                            Text(s.label).tag(s)
                        }
                    }
                }

                Section("Image") {
                    if let image = selectedImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 200)
                            .cornerRadius(8)
                    }

                    Button("Select Image") {
                        showImagePicker = true
                    }
                }

                Section {
                    Button("Save Project") {
                        runPipeline()
                    }
                    .disabled(isSaving || name.isEmpty)
                }
            }
            .navigationTitle("New Project")
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePicker { image in
                selectedImage = image
            }
        }
    }

    // MARK: - Actions
    private func runPipeline() {
        isSaving = true
        // your Supabase + webhook integration logic here
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            isSaving = false
            dismiss()
        }
    }
}

