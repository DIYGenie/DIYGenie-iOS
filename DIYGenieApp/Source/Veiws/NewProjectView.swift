import SwiftUI
import PhotosUI
import Supabase
import AVFoundation

struct NewProjectView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var name: String = ""
    @State private var description: String = ""
    @State private var showingCamera = false
    @State private var showingMeasurePrompt = false
    @State private var showingARMeasure = false
    @State private var capturedImage: UIImage? = nil
    @State private var showingToast = false
    @State private var toastMessage = ""
    @State private var isUploading = false
    @FocusState private var focusedField: Bool

    private let supabase = SupabaseClient(
        supabaseURL: URL(string: Bundle.main.object(forInfoDictionaryKey: "SUPABASE_URL") as? String ?? "")!,
        supabaseKey: Bundle.main.object(forInfoDictionaryKey: "SUPABASE_ANON_KEY") as? String ?? ""
    )

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color.black, Color.purple.opacity(0.4)], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            VStack(spacing: 22) {
                Text("New Project")
                    .font(.custom("Manrope-Bold", size: 30))
                    .foregroundColor(.white)
                    .padding(.top, 20)

                VStack(spacing: 16) {
                    TextField("e.g. Bathroom Vanity Remodel", text: $name)
                        .padding()
                        .font(.custom("Inter-Regular", size: 16))
                        .foregroundColor(.white)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(10)
                        .focused($focusedField)
                        .disableAutocorrection(true)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .strokeBorder(Color.white.opacity(0.2))
                        )

                    TextField("Describe your DIY goal...", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                        .padding()
                        .font(.custom("Inter-Regular", size: 16))
                        .foregroundColor(.white)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(10)
                        .disableAutocorrection(true)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .strokeBorder(Color.white.opacity(0.2))
                        )
                }
                .padding(.horizontal)

                Spacer()

                if let image = capturedImage {
                    VStack(spacing: 10) {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: 250, maxHeight: 180)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .shadow(radius: 6)

                        Button("Retake Photo") {
                            showingCamera = true
                        }
                        .font(.custom("Inter-Medium", size: 15))
                        .foregroundColor(.white.opacity(0.8))
                    }
                } else {
                    Button {
                        showingCamera = true
                    } label: {
                        Text("📸 Take Photo & Measure Room")
                            .font(.custom("Manrope-SemiBold", size: 18))
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.purple)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                            .shadow(radius: 4)
                    }
                    .padding(.horizontal, 40)
                }

                Spacer()
            }
            .padding(.bottom, 60)

            if showingToast {
                VStack {
                    Spacer()
                    Text(toastMessage)
                        .font(.custom("Inter-Medium", size: 15))
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(Color.black.opacity(0.8))
                        .cornerRadius(20)
                        .padding(.bottom, 30)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .animation(.easeInOut(duration: 0.4), value: showingToast)
                }
            }
        }
        .sheet(isPresented: $showingCamera) {
            CameraView(onPhotoCaptured: { image in
                capturedImage = image
                showingCamera = false
                showingMeasurePrompt = true
                uploadPhoto(image)
            })
        }
        .alert("Would you like to measure your room now?", isPresented: $showingMeasurePrompt) {
            Button("Yes") { showingARMeasure = true }
            Button("Skip", role: .cancel) { showingARMeasure = false }
        }
        .sheet(isPresented: $showingARMeasure) {
            ARMeasureView { _ in
                showingARMeasure = false
            }
        }
    }

    private func uploadPhoto(_ image: UIImage) {
        guard let data = image.jpegData(compressionQuality: 0.8) else { return }
        isUploading = true
        Task {
            do {
                let fileName = "roomphoto_\(UUID().uuidString).jpg"
                try await supabase.storage.from("uploads").upload(fileName, data: data, options: FileOptions(contentType: "image/jpeg"))
                await MainActor.run {
                    showToast("Room photo saved ✅")
                }
            } catch {
                await MainActor.run {
                    showToast("Upload failed: \(error.localizedDescription)")
                }
            }
            isUploading = false
        }
    }

    private func showToast(_ message: String) {
        toastMessage = message
        withAnimation {
            showingToast = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation {
                showingToast = false
            }
        }
    }
}

// MARK: - CameraView
struct CameraView: UIViewControllerRepresentable {
    var onPhotoCaptured: (UIImage) -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: CameraView
        init(_ parent: CameraView) { self.parent = parent }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.onPhotoCaptured(image)
            }
            picker.dismiss(animated: true)
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}
