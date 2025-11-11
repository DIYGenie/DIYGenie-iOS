//
//  NewProjectView.swift
//

import SwiftUI

struct NewProjectView: View {
    @State private var capturedImage: UIImage?
    @State private var overlaySaved = false
    @AppStorage("overlaySaved_current") private var overlaySavedPersist: Bool = false
    private var isOverlaySaved: Bool { overlaySaved || overlaySavedPersist }

    @State private var showingOverlayEditor = false
    @State private var overlayRect: CGRect = .zero
    @State private var showSaveBanner = false

    var body: some View {
        VStack {
            // ... other UI elements ...

            Text("AR Scan For Measurement Accuracy")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.top, 8)

            Button("Start AR") {
                // Start AR action
            }
            .disabled(!isOverlaySaved)
            .opacity(isOverlaySaved ? 1 : 0.5)

            if !isOverlaySaved {
                Text("Please save the overlay before starting AR.")
                    .foregroundColor(.red)
            }

            // ... other UI elements ...

            if showSaveBanner || overlaySavedPersist {
                Text("Photo + Area Saved")
                    .padding()
                    .background(Color.green.opacity(0.8))
                    .cornerRadius(8)
                    .transition(.opacity)
            }
        }
        .sheet(isPresented: $showingOverlayEditor) {
            OverlayEditorView(
                image: capturedImage!,
                initialRect: overlayRect,
                onConfirm: { confirmedRect in
                    self.overlayRect = confirmedRect
                    self.overlaySaved = true
                    self.overlaySavedPersist = true
                    self.showSaveBanner = true
                    self.showingOverlayEditor = false
                },
                onCancel: {
                    self.showingOverlayEditor = false
                }
            )
        }
        .onAppear {
            if overlaySavedPersist {
                showSaveBanner = true
            }
        }
        .onChange(of: capturedImage) { _ in
            // No action needed here for this task
        }
    }

    func capturePhoto() {
        // After capturing photo:
        if let image = /* captured image from camera */ nil {
            self.capturedImage = image
            self.overlaySaved = false
            self.overlaySavedPersist = false
            self.showingOverlayEditor = true
        }
    }

    func uploadPhoto() {
        // After uploading photo:
        if let image = /* uploaded image */ nil {
            self.capturedImage = image
            self.overlaySaved = false
            self.overlaySavedPersist = false
            self.showingOverlayEditor = true
        }
    }
}
