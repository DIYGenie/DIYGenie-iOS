//
//  NewProjectView.swift
//  DIYGenieApp
//

import SwiftUI
import PhotosUI

struct NewProjectView: View {
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isFocused: Bool

    @State private var name = ""
    @State private var goal = ""
    @State private var budget = "$$"
    @State private var skill = "intermediate"

    @State private var showingCamera = false
    @State private var showingPicker = false
    @State private var selectedImage: UIImage?
    @State private var showBanner = false
    @State private var isLoading = false
    @State private var showAlert = false
    @State private var alertMessage = ""

    @State private var projectId: String?

    private let apiBase = "https://api.diygenieapp.com"

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 28/255, green: 26/255, blue: 40/255),
                    Color(red: 58/255, green: 35/255, blue: 110/255)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    HStack {
                        Button(action: { dismiss() }) {
                            Image(systemName: "chevron.left")
                                .foregroundColor(.white.opacity(0.9))
                                .font(.system(size: 18, weight: .semibold))
                        }
                        Spacer()
                    }

                    Text("New Project")
                        .font(.system(size: 34, weight: .bold))
                        .foregroundColor(.white)
                    Text("Plan your next project like a pro 🔧")
                        .foregroundColor(.white.opacity(0.7))

                    groupBox {
                        TextField("e.g. Floating Shelves", text: $name)
                            .focused($isFocused)
                            .padding(12)
                            .background(.black.opacity(0.2))
                            .cornerRadius(12)
                            .foregroundColor(.white)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.words)
                    } label: {
                        label("Project Name")
                    }

                    groupBox {
                        ZStack(alignment: .topLeading) {
                            TextEditor(text: $goal)
                                .focused($isFocused)
                                .frame(minHeight: 120)
                                .padding(8)
                                .background(.black.opacity(0.2))
                                .cornerRadius(12)
                                .foregroundColor(.white)
                            if goal.isEmpty {
                                Text("Describe what you'd like to build…")
                                    .foregroundColor(.white.opacity(0.35))
                                    .padding(.top, 16)
                                    .padding(.leading, 12)
                            }
                        }
                    } label: {
                        label("Goal / Description")
                    }

                    groupBox {
                        Picker("Budget", selection: $budget) {
                            Text("$").tag("$")
                            Text("$$").tag("$$")
                            Text("$$$").tag("$$$")
                        }
                        .pickerStyle(.segmented)
                    } label: {
                        label("Budget")
                    }

                    groupBox {
                        Picker("Skill", selection: $skill) {
                            Text("Beginner").tag("beginner")
                            Text("Intermediate").tag("intermediate")
                            Text("Advanced").tag("advanced")
                        }
                        .pickerStyle(.segmented)
                    } label: {
                        label("Skill Level")
                    }

                    if selectedImage == nil {
                        VStack(spacing: 14) {
                            Button {
                                isFocused = false
                                showingCamera = true
                            } label: {
                                heroButton("Take Photo for Measurements")
                            }

                            Button {
                                isFocused = false
                                showingPicker = true
                            } label: {
                                secondaryButton("Upload Photo")
                            }
                        }
                    }

                    if let img = selectedImage {
                        HStack(spacing: 14) {
                            Image(uiImage: img)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 64, height: 64)
                                .clipped()
                                .cornerRadius(12)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Photo saved ✅")
                                    .foregroundColor(.white)
                                    .font(.headline)
                                Text("Ready to generate your plan.")
                                    .foregroundColor(.white.opacity(0.7))
                                    .font(.subheadline)
                            }
                            Spacer()
                        }

                        if showBanner {
                            Text("Photo saved ✅")
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(.white)
                                .padding(10)
                                .background(Color.black.opacity(0.5))
                                .cornerRadius(12)
                                .padding(.top, 8)
                                .transition(.opacity)
                        }

                        VStack(spacing: 14) {
                            Button {
                                if let id = projectId {
                                    triggerPreview(projectId: id)
                                }
                            } label: {
                                heroButton("Generate AI Plan + Preview")
                            }
                            .disabled(projectId == nil || isLoading)

                            Button {
                                if let id = projectId {
                                    triggerBuildOnly(projectId: id)
                                }
                            } label: {
                                secondaryButton("Create Plan Only")
                            }
                            .disabled(projectId == nil || isLoading)
                        }
                        .padding(.top, 8)
                    }

                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 60)
            }
        }
        .sheet(isPresented: $showingCamera) {
            ImagePicker(sourceType: .camera) { image in
                handleImage(image)
            }
        }
        .sheet(isPresented: $showingPicker) {
            ImagePicker(sourceType: .photoLibrary) { image in
                handleImage(image)
            }
        }
        .alert("Status", isPresented: $showAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
    }

    private func handleImage(_ image: UIImage?) {
        guard let image = image else { return }
        selectedImage = image
        hideKeyboard()
        Task {
            await createProjectAndUpload(image)
        }
    }

    private func createProjectAndUpload(_ image: UIImage) async {
        guard !name.isEmpty, goal.count >= 15 else {
            alertMessage = "Please fill all required fields."
            showAlert = true
            return
        }
        isLoading = true
        defer { isLoading = false }

        guard let userId = UserDefaults.standard.string(forKey: "user_id") else {
            alertMessage = "Missing user ID"
            showAlert = true
            return
        }

        let createBody: [String: Any] = [
            "user_id": userId,
            "name": name,
            "goal": goal,
            "budget": budget,
            "skill_level": skill
        ]
        guard let body = try? JSONSerialization.data(withJSONObject: createBody) else { return }

        do {
            var req = URLRequest(url: URL(string: "\(apiBase)/api/projects")!)
            req.httpMethod = "POST"
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            req.httpBody = body
            let (data, _) = try await URLSession.shared.data(for: req)
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let item = json["item"] as? [String: Any],
               let id = item["id"] as? String {
                projectId = id
                await uploadImage(image, projectId: id)
            }
        } catch {
            alertMessage = "Error creating project: \(error.localizedDescription)"
            showAlert = true
        }
    }

    private func uploadImage(_ image: UIImage, projectId: String) async {
        guard let data = image.jpegData(compressionQuality: 0.8) else { return }
        let boundary = UUID().uuidString
        guard let url = URL(string: "\(apiBase)/api/projects/\(projectId)/image") else { return }

        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()
        let lineBreak = "\r\n"

        body.append("--\(boundary)\(lineBreak)".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"photo.jpg\"\(lineBreak)".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\(lineBreak + lineBreak)".data(using: .utf8)!)
        body.append(data)
        body.append("\(lineBreak)--\(boundary)--\(lineBreak)".data(using: .utf8)!)

        req.httpBody = body

        do {
            _ = try await URLSession.shared.data(for: req)
            withAnimation(.easeInOut(duration: 0.4)) {
                showBanner = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                withAnimation { showBanner = false }
            }
        } catch {
            alertMessage = "Upload failed: \(error.localizedDescription)"
            showAlert = true
        }
    }


    private func triggerPreview(projectId: String) {
        guard let userId = UserDefaults.standard.string(forKey: "user_id") else { return }
        Task {
            var req = URLRequest(url: URL(string: "\(apiBase)/api/projects/\(projectId)/preview?user_id=\(userId)")!)
            req.httpMethod = "POST"
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            _ = try? await URLSession.shared.data(for: req)
            alertMessage = "Preview generation started."
            showAlert = true
        }
    }

    private func triggerBuildOnly(projectId: String) {
        guard let userId = UserDefaults.standard.string(forKey: "user_id") else { return }
        Task {
            var req = URLRequest(url: URL(string: "\(apiBase)/api/projects/\(projectId)/build-without-preview?user_id=\(userId)")!)
            req.httpMethod = "POST"
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            _ = try? await URLSession.shared.data(for: req)
            alertMessage = "Plan generation started."
            showAlert = true
        }
    }

    private func groupBox<Content: View>(@ViewBuilder content: () -> Content, label: () -> Text) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            label()
            content()
        }
        .padding(16)
        .background(Color.white.opacity(0.07))
        .cornerRadius(16)
    }

    private func label(_ text: String) -> Text {
        Text(text.uppercased())
            .font(.system(size: 14, weight: .semibold))
            .foregroundColor(.white.opacity(0.9))
    }

    private func heroButton(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 18, weight: .bold))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                LinearGradient(colors: [
                    Color(red: 115/255, green: 73/255, blue: 224/255),
                    Color(red: 146/255, green: 86/255, blue: 255/255)
                ], startPoint: .leading, endPoint: .trailing)
            )
            .foregroundColor(.white)
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.25), radius: 12, x: 0, y: 8)
    }

    private func secondaryButton(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 17, weight: .semibold))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .background(Color.white.opacity(0.08))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.18), lineWidth: 1))
            .foregroundColor(.white)
            .cornerRadius(14)
    }

    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
