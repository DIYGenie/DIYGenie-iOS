//
//  NewProjectView.swift
//  DIYGenieApp
//

import SwiftUI
import UIKit

#if canImport(RoomPlan)
import RoomPlan
#endif

struct NewProjectView: View {
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isFocused: Bool

    // MARK: - Form
    @State private var name: String = ""
    @State private var goal: String = ""
    @State private var budget: String = "$$"
    @State private var skill: String = "beginner"

    // MARK: - Media / Flow
    @State private var showingCamera = false
    @State private var showingPicker = false
    @State private var capturedImage: UIImage?
    @State private var projectId: String?

    // MARK: - Navigation trigger → Project Details
    @State private var goToDetails = false
    @State private var createdProject: Project?

    // MARK: - UX
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var isLoading = false

    private let api = ProjectsService(
        userId: UserDefaults.standard.string(forKey: "user_id") ?? UUID().uuidString
    )

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 28/255, green: 26/255, blue: 40/255),
                    Color(red: 58/255, green: 35/255, blue: 110/255)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {

                    // Header
                    Text("New Project")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.top, 8)

                    // Form fields
                    Group {
                        labeledField("Project name", text: $name, placeholder: "e.g. Floating Shelves")
                        labeledField("Your goal", text: $goal, placeholder: "Describe the outcome you want")
                        pickerRow(title: "Budget", selection: $budget, options: ["$", "$$", "$$$"])
                        pickerRow(title: "Skill level", selection: $skill, options: ["beginner", "intermediate", "advanced"])
                    }

                    // Image chooser
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Room photo")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)

                        if let img = capturedImage {
                            Image(uiImage: img)
                                .resizable()
                                .scaledToFit()
                                .cornerRadius(14)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(Color.white.opacity(0.18), lineWidth: 1)
                                )
                                .shadow(color: .black.opacity(0.25), radius: 8, x: 0, y: 4)
                                .padding(.bottom, 6)

                            // ✅ AR button appears UNDER the image card (only after image exists)
                            #if canImport(RoomPlan)
                            if #available(iOS 17.0, *) {
                                if projectId != nil {
                                    Button {
                                        showingARScanner = true
                                    } label: {
                                        secondaryButton("Scan Room (AR)")
                                    }
                                } else {
                                    Text("Create the project below to enable AR scanning.")
                                        .font(.footnote)
                                        .foregroundColor(.white.opacity(0.6))
                                }
                            }
                            #endif
                        } else {
                            HStack(spacing: 12) {
                                Button {
                                    showingPicker = true
                                } label: {
                                    secondaryButton("Choose Photo")
                                }
                                Button {
                                    showingCamera = true
                                } label: {
                                    secondaryButton("Take Photo")
                                }
                            }
                        }
                    }

                    // Primary & Secondary actions (stay at bottom, NOT next to AR)
                    VStack(spacing: 12) {
                        Button {
                            Task { await createProjectAndUpload(generatePreview: true) }
                        } label: {
                            primaryButton("Generate AI Plan + Preview")
                        }
                        Button {
                            Task { await createProjectAndUpload(generatePreview: false) }
                        } label: {
                            secondaryButton("Create Plan Only (no preview)")
                        }
                    }
                    .padding(.top, 10)

                    Spacer(minLength: 20)
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
            }

            if isLoading {
                ProgressView().tint(.white)
            }
        }
        // Image pickers
        .sheet(isPresented: $showingPicker) {
            ImagePicker(sourceType: .photoLibrary) { img in
                capturedImage = img
            }
        }
        .sheet(isPresented: $showingCamera) {
            ImagePicker(sourceType: .camera) { img in
                capturedImage = img
            }
        }
        // AR sheet (only after a project exists)
        #if canImport(RoomPlan)
        .sheet(isPresented: $showingARScanner) {
            if let id = projectId {
                if #available(iOS 17.0, *) {
                    ARRoomPlanSheet(projectId: id) { usdzURL in
                        Task {
                            do {
                                try await api.uploadARScan(projectId: id, fileURL: usdzURL)
                                print("✅ AR scan uploaded for project \(id)")
                            } catch {
                                print("❌ Upload AR scan failed:", error.localizedDescription)
                            }
                        }
                    }
                    .ignoresSafeArea()
                } else {
                    Text("RoomPlan requires iOS 17+").padding()
                }
            } else {
                Text("Create the project first to attach a scan.").padding()
            }
        }
        #endif
        // Hidden navigation trigger
        .background(
            NavigationLink(
                destination: Group {
                    if let p = createdProject {
                        ProjectDetailsView(project: p)
                    } else {
                        EmptyView()
                    }
                },
                isActive: $goToDetails,
                label: { EmptyView() }
            )
        )
        // Alerts
        .alert("Notice", isPresented: $showAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Close") { dismiss() }.foregroundColor(.white)
            }
        }
    }

    // MARK: - AR state (kept local to this file)
    #if canImport(RoomPlan)
    @State private var showingARScanner = false
    #endif

    // MARK: - Actions
    @MainActor
    private func createProjectAndUpload(generatePreview: Bool) async {
        guard !name.isEmpty, !goal.isEmpty, let image = capturedImage else {
            alertMessage = "Please fill all required fields and add a room photo."
            showAlert = true
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            // 1) Create the project
            let created = try await api.createProject(
                name: name,
                goal: goal,
                budget: budget,
                skillLevel: skill
            )
            self.projectId = created.id

            // 2) Upload the input image
            try await api.uploadImage(projectId: created.id, image: image)

            // 3) Optionally request preview generation on backend
            if generatePreview {
                try await api.requestPreview(projectId: created.id)
            }

            // 4) Fetch fresh project for details screen (optional)
            self.createdProject = created
            self.goToDetails = true

        } catch {
            alertMessage = "Failed to create project: \(error.localizedDescription)"
            showAlert = true
        }
    }

    // MARK: - Small UI helpers
    private func labeledField(_ title: String, text: Binding<String>, placeholder: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
            TextField(placeholder, text: text)
                .textInputAutocapitalization(.sentences)
                .disableAutocorrection(false)
                .padding(12)
                .background(Color.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.18), lineWidth: 1)
                )
                .cornerRadius(12)
                .foregroundColor(.white)
        }
    }

    private func pickerRow(title: String, selection: Binding<String>, options: [String]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
            Picker("", selection: selection) {
                ForEach(options, id: \.self) { v in
                    Text(v.capitalized).tag(v)
                }
            }
            .pickerStyle(.segmented)
            .padding(4)
            .background(Color.white.opacity(0.06))
            .cornerRadius(12)
        }
    }

    private func primaryButton(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 17, weight: .bold))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .background(
                LinearGradient(colors: [
                    Color(red: 115/255, green: 73/255, blue: 224/255),
                    Color(red: 146/255, green: 86/255, blue: 255/255)
                ], startPoint: .leading, endPoint: .trailing)
            )
            .foregroundColor(.white)
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.25), radius: 8, x: 0, y: 4)
    }

    private func secondaryButton(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 16, weight: .semibold))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Color.white.opacity(0.08))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.white.opacity(0.18), lineWidth: 1)
            )
            .foregroundColor(.white)
            .cornerRadius(14)
    }
}

