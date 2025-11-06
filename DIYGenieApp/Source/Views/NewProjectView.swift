import SwiftUI
import PhotosUI
import UIKit

#if canImport(RoomPlan)
import RoomPlan
#endif

struct NewProjectView: View {
  // MARK: - Env / Focus
  @Environment(\.dismiss) private var dismiss
  @FocusState private var isFocused: Bool

  // MARK: - Form
  @State private var name: String = ""
  @State private var goal: String = ""
  @State private var budget: String = "$"
  @State private var skill: String = "Beginner"

  // MARK: - Media / Flow
  @State private var showingPicker = false
  @State private var showingCamera = false
  @State private var showingARScanner = false
  @State private var capturedImage: UIImage?
  @State private var projectId: String?

  // MARK: - UX
  @State private var showAlert = false
  @State private var alertMessage = ""
  @State private var isLoading = false

  // MARK: - API
  private let api = ProjectsService(
    userId: UserDefaults.standard.string(forKey: "user_id") ?? UUID().uuidString
  )

  var body: some View {
    ZStack {
      // Brand gradient
      LinearGradient(
        colors: [
          Color(red: 0.20, green: 0.06, blue: 0.38),
          Color(red: 0.49, green: 0.26, blue: 0.89)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
      )
      .ignoresSafeArea()

      ScrollView {
        VStack(alignment: .leading, spacing: 16) {

          // Header
          HStack {
            Button {
              dismiss()
            } label: {
              Image(systemName: "chevron.backward")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
                .padding(10)
                .background(
                  Color.white.opacity(0.12),
                  in: RoundedRectangle(cornerRadius: 12, style: .continuous)
                )
            }
            Spacer()
          }
          .padding(.top, 8)

          Text("New Project")
            .font(.system(size: 34, weight: .bold))
            .foregroundColor(.white)

          Text("Get everything you need to bring your next DIY idea to life.")
            .font(.subheadline)
            .foregroundColor(.white.opacity(0.85))

          // Project name
          sectionCard {
            VStack(alignment: .leading, spacing: 8) {
              label("PROJECT NAME")
              TextField("e.g. Floating Shelves", text: $name)
                .textFieldStyle(.plain)
                .padding(14)
                .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
                .foregroundColor(.white)
                .submitLabel(.done)
                .focused($isFocused)
            }
          }

          // Goal
          sectionCard {
            VStack(alignment: .leading, spacing: 8) {
              label("GOAL / DESCRIPTION")
              TextEditor(text: Binding(
                get: { goal },
                set: { goal = $0 }
              ))
              .frame(minHeight: 120)
              .padding(10)
              .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
              .foregroundColor(.white)
              .overlay(
                Group {
                  if goal.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text("Describe what you'd like to build…")
                      .foregroundColor(.white.opacity(0.5))
                      .padding(.horizontal, 16)
                      .padding(.vertical, 16)
                      .frame(maxWidth: .infinity, alignment: .leading)
                  }
                }
              )
            }
          }

          // Budget
          sectionCard {
            VStack(alignment: .leading, spacing: 10) {
              label("BUDGET")
              HStack(spacing: 12) {
                budgetButton("$")
                budgetButton("$$")
                budgetButton("$$$")
              }
              Text("Your project budget range.")
                .font(.footnote)
                .foregroundColor(.white.opacity(0.7))
            }
          }

          // Skill level
          sectionCard {
            VStack(alignment: .leading, spacing: 10) {
              label("SKILL LEVEL")
              HStack(spacing: 12) {
                skillButton("Beginner")
                skillButton("Intermediate")
                skillButton("Advanced")
              }
              Text("Your current DIY experience.")
                .font(.footnote)
                .foregroundColor(.white.opacity(0.7))
            }
          }

          // AR button (gated until project exists)
          sectionCard {
            VStack(spacing: 4) {
              Button {
                if projectId == nil {
                  // Gate: must create project first
                  alertMessage = "Create the project first to attach an AR scan."
                  showAlert = true
                } else {
                  showingARScanner = true
                }
              } label: {
                HStack(spacing: 10) {
                  Image(systemName: "viewfinder")
                  Text("Add AR Scan Accuracy")
                  Spacer()
                  if projectId == nil {
                    Text("Create the project first")
                      .font(.footnote)
                      .foregroundColor(.white.opacity(0.7))
                  }
                }
                .foregroundColor(.white)
                .padding(.vertical, 14)
                .padding(.horizontal, 12)
                .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 14))
              }
              .disabled(projectId == nil)
            }
          }

          // Room photo card + actions
          sectionCard {
            VStack(alignment: .leading, spacing: 12) {
              label("ROOM PHOTO")

              if let image = capturedImage {
                HStack(alignment: .top, spacing: 14) {
                  Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 120, height: 120)
                    .clipped()
                    .cornerRadius(12)

                  VStack(alignment: .leading, spacing: 6) {
                    Text("Photo attached")
                      .foregroundColor(.white)
                      .fontWeight(.semibold)
                    Text("Use AR or take another photo for measurement accuracy.")
                      .foregroundColor(.white.opacity(0.8))
                      .font(.footnote)

                    Button {
                      // Redo selection
                      capturedImage = nil
                      projectId = nil // force re-create on next generate
                    } label: {
                      Text("Redo")
                        .font(.footnote)
                        .underline()
                    }
                    .foregroundColor(.white.opacity(0.9))
                    .padding(.top, 4)
                  }
                  Spacer()
                }
              } else {
                Button {
                  showingPicker = true
                } label: {
                  HStack(spacing: 10) {
                    Image(systemName: "photo.on.rectangle.angled")
                    Text("Add a room photo")
                    Spacer()
                  }
                  .foregroundColor(.white)
                  .padding(.vertical, 14)
                  .padding(.horizontal, 12)
                  .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 14))
                }
              }

              Button {
                showingCamera = true
              } label: {
                HStack(spacing: 10) {
                  Image(systemName: "camera.viewfinder")
                  Text("Take Photo for Measurements")
                  Spacer()
                }
                .foregroundColor(.white)
                .padding(.vertical, 14)
                .padding(.horizontal, 12)
                .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 14))
              }
            }
          }

          // Primary actions
          VStack(spacing: 12) {
            Button {
              Task { await generate(createPreview: true) }
            } label: {
              Text("Generate AI Plan + Preview")
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                  LinearGradient(
                    colors: [
                      Color.white.opacity(0.35),
                      Color.white.opacity(0.75)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                  ),
                  in: RoundedRectangle(cornerRadius: 16, style: .continuous)
                )
                .foregroundColor(.black)
            }
            .disabled(isLoading || capturedImage == nil || name.isEmpty)

            Button {
              Task { await generate(createPreview: false) }
            } label: {
              Text("Create Plan Only (no preview)")
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 16))
                .foregroundColor(.white)
            }
            .disabled(isLoading || capturedImage == nil || name.isEmpty)
          }
          .padding(.top, 8)

        } // VStack
        .padding(.horizontal, 20)
        .padding(.bottom, 40)
      } // ScrollView
      .scrollDismissesKeyboard(.interactively)

      if isLoading {
        Color.black.opacity(0.25).ignoresSafeArea()
        ProgressView().tint(.white)
      }
    }
    .photosPicker(isPresented: $showingPicker, selection: .constant(nil), matching: .images)
    .onChange(of: showingPicker) { _ in
      // handled below via a helper
    }
    .sheet(isPresented: $showingPicker) {
      // Lightweight wrapper to keep compatibility on older codebases
      PhotoPickerView { img in
        if let img { capturedImage = img }
      }
    }
    .sheet(isPresented: $showingCamera) {
      CameraPickerView { img in
        if let img { capturedImage = img }
      }
    }

    #if canImport(RoomPlan)
    .sheet(isPresented: $showingARScanner) {
      if let id = projectId {
        if #available(iOS 17.0, *) {
          ARRoomPlanSheet(projectId: id) { _ in
            // usdz URL returned — you can upload here if you want
          }
        } else {
          Text("RoomPlan requires iOS 17+.")
            .padding()
        }
      } else {
        Text("Create the project first.")
          .padding()
      }
    }
    #endif

    .alert("Heads up", isPresented: $showAlert, actions: {
      Button("OK", role: .cancel) { }
    }, message: {
      Text(alertMessage)
    })
  }

  // MARK: - UI helpers

  private func label(_ text: String) -> some View {
    Text(text)
      .font(.footnote)
      .foregroundColor(.white.opacity(0.85))
  }

  private func sectionCard<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
    VStack(alignment: .leading, spacing: 12) {
      content()
    }
    .padding(16)
    .background(Color.white.opacity(0.10), in: RoundedRectangle(cornerRadius: 18))
  }

  private func budgetButton(_ value: String) -> some View {
    Button {
      budget = value
    } label: {
      Text(value)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(
          (budget == value ? Color.white.opacity(0.28) : Color.white.opacity(0.10)),
          in: RoundedRectangle(cornerRadius: 14)
        )
        .foregroundColor(.white)
    }
  }

  private func skillButton(_ value: String) -> some View {
    Button {
      skill = value
    } label: {
      Text(value)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(
          (skill == value ? Color.white.opacity(0.28) : Color.white.opacity(0.10)),
          in: RoundedRectangle(cornerRadius: 14)
        )
        .foregroundColor(.white)
    }
  }

  // MARK: - Flow

  private func generate(createPreview: Bool) async {
    guard let image = capturedImage else {
      alertMessage = "Please add a room photo first."
      showAlert = true
      return
    }
    isLoading = true
    defer { isLoading = false }

    do {
      // 1) If no project yet, create
      if projectId == nil {
        let created = try await api.createProject(
          name: name,
          goal: goal,
          budget: budget,
          skillLevel: skill
        )
        projectId = created.id
      }

      guard let pid = projectId else { return }

      // 2) Upload image
      try await api.uploadImage(projectId: pid, image: image)

      // 3) (Optional) trigger preview — intentionally omitted to avoid
      //    compile errors if your service doesn’t expose it.
      // if createPreview { try await api.requestPreview(projectId: pid) }

      // 4) Success: pop to previous or route to details (keeping simple: dismiss)
      dismiss()

    } catch {
      alertMessage = "Failed: \(error.localizedDescription)"
      showAlert = true
    }
  }
}

// MARK: - Simple Pickers (self-contained)

/// Photos picker wrapper (library)
private struct PhotoPickerView: UIViewControllerRepresentable {
  var onImage: (UIImage?) -> Void

  func makeCoordinator() -> Coordinator { Coordinator(onImage: onImage) }

  func makeUIViewController(context: Context) -> PHPickerViewController {
    var config = PHPickerConfiguration()
    config.selectionLimit = 1
    config.filter = .images
    let picker = PHPickerViewController(configuration: config)
    picker.delegate = context.coordinator
    return picker
  }

  func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

  final class Coordinator: NSObject, PHPickerViewControllerDelegate {
    let onImage: (UIImage?) -> Void
    init(onImage: @escaping (UIImage?) -> Void) { self.onImage = onImage }

    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
      picker.dismiss(animated: true)
      guard let provider = results.first?.itemProvider, provider.canLoadObject(ofClass: UIImage.self) else {
        onImage(nil); return
      }
      provider.loadObject(ofClass: UIImage.self) { object, _ in
        DispatchQueue.main.async {
          self.onImage(object as? UIImage)
        }
      }
    }
  }
}

/// Camera picker wrapper
private struct CameraPickerView: UIViewControllerRepresentable {
  var onImage: (UIImage?) -> Void

  final class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    var parent: CameraPickerView
    init(_ parent: CameraPickerView) { self.parent = parent }

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
      let img = (info[.editedImage] ?? info[ .originalImage ]) as? UIImage
      picker.dismiss(animated: true) { self.parent.onImage(img) }
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
      picker.dismiss(animated: true) { self.parent.onImage(nil) }
    }
  }

  func makeCoordinator() -> Coordinator { Coordinator(self) }

  func makeUIViewController(context: Context) -> UIImagePickerController {
    let picker = UIImagePickerController()
    picker.sourceType = .camera
    picker.allowsEditing = false
    picker.delegate = context.coordinator
    return picker
  }

  func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
}
