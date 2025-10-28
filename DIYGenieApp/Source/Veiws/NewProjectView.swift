import SwiftUI
import PhotosUI
import Supabase

@available(iOS 15.0, *)
struct NewProjectView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var projectName = ""
    @State private var projectDescription = ""
    @State private var showingImagePicker = false
    @State private var selectedImage: UIImage?
    @State private var showingMeasureView = false
    @State private var measuredWidth: Double?
    @State private var measuredHeight: Double?
    @State private var isUploading = false
    @State private var showingAlert = false
    @State private var alertMessage = ""

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.black, Color(.systemGray6)],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    Text("New Project")
                        .font(.largeTitle.bold())
                        .foregroundColor(.white)
                        .padding(.top, 30)

                    VStack(alignment: .leading, spacing: 16) {
                        Text("Project Name")
                            .font(.headline)
                            .foregroundColor(.white.opacity(0.8))
                        TextField("e.g. Floating Shelves", text: $projectName)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(10)

                        Text("Goal / Description")
                            .font(.headline)
                            .foregroundColor(.white.opacity(0.8))
                        TextField("Describe what you’d like to build...", text: $projectDescription, axis: .vertical)
                            .lineLimit(3...6)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(10)
                    }
                    .padding(.horizontal)

                    if let image = selectedImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .cornerRadius(12)
                            .padding(.horizontal)
                            .overlay(
                                VStack {
                                    Spacer()
                                    if let w = measuredWidth, let h = measuredHeight {
                                        Text(String(format: "Measured: %.1f\" × %.1f\"", w, h))
                                            .font(.caption.bold())
                                            .padding(6)
                                            .background(Color.black.opacity(0.6))
                                            .cornerRadius(8)
                                            .foregroundColor(.white)
                                            .padding(8)
                                    }
                                }
                            )
                    }

                    Button {
                        showingImagePicker = true
                    } label: {
                        Label("Take Photo & Measure Room", systemImage: "camera.viewfinder")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .foregroundColor(.white)
                            .background(Color(red: 113/255, green: 66/255, blue: 255/255))
                            .cornerRadius(12)
                            .padding(.horizontal)
                    }

                    if isUploading {
                        ProgressView("Uploading...")
                            .tint(Color.purple)
                    }

                    Button(action: saveProject) {
                        Label("Save Project", systemImage: "tray.and.arrow.down.fill")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .foregroundColor(.white)
                            .background(Color.green)
                            .cornerRadius(12)
                            .padding(.horizontal)
                    }
                    .disabled(projectName.isEmpty || projectDescription.count < 5 || selectedImage == nil)
                    .opacity((projectName.isEmpty || projectDescription.count < 5 || selectedImage == nil) ? 0.6 : 1)
                }
                .padding(.bottom, 40)
            }
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker { image in
                selectedImage = image
                showingImagePicker = false
                // Auto open measure view
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    showingMeasureView = true
                }
            }
        }
        .sheet(isPresented: $showingMeasureView) {
            MeasureOverlayView { width, height in
                measuredWidth = width
                measuredHeight = height
                showingMeasureView = false
            }
        }
        .alert("Upload Status", isPresented: $showingAlert) {
            Button("OK", role: .cancel) { dismiss() }
        } message: {
            Text(alertMessage)
        }
    }

    private func saveProject() {
        guard let image = selectedImage else { return }
        isUploading = true

        Task {
            do {
                guard let imageData = image.jpegData(compressionQuality: 0.8) else { return }
                let filename = "uploads/\(UUID().uuidString).jpg"

                // ✅ Updated Supabase Swift API call
                try await client.storage.from("uploads").upload(filename, data: imageData)

                alertMessage = "✅ Project saved with measurements and photo!"
            } catch {
                alertMessage = "Upload failed: \(error.localizedDescription)"
            }

            isUploading = false
            showingAlert = true
        }
    }
}

// MARK: - Simple Image Picker
struct ImagePicker: UIViewControllerRepresentable {
    var onPick: (UIImage) -> Void

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .camera
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        var parent: ImagePicker
        init(_ parent: ImagePicker) { self.parent = parent }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.onPick(image)
            }
            picker.dismiss(animated: true)
        }
    }
}
