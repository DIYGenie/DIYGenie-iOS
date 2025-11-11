//
//  ARScannerSheet.swift
//  DIYGenieApp
//
//  Self‑contained RealityKit AR sheet.
//  Note: Data entry and photo/overlay happen on New Project; this sheet only runs the live AR session.
//

import SwiftUI
import RealityKit
import ARKit
import AVFoundation

struct ARScannerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var cameraDenied = false
    @State private var sessionError: String?

    var body: some View {
        ZStack {
            if ARWorldTrackingConfiguration.isSupported {
                ARViewContainer(sessionError: $sessionError)
                    .ignoresSafeArea()
            } else {
                UnsupportedView()
            }

            VStack {
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28, weight: .semibold))
                            .padding(12)
                    }
                    Spacer()
                }
                Spacer()
            }

            if cameraDenied {
                ErrorOverlay(
                    title: "Camera Access Needed",
                    message: "Enable camera in Settings → Privacy → Camera to use AR features."
                )
            } else if let sessionError {
                ErrorOverlay(title: "AR Session Error", message: sessionError)
            }
        }
        .task {
            let auth = await AVCaptureDevice.requestAccess(for: .video)
            cameraDenied = !auth
        }
    }
}

private struct ARViewContainer: UIViewRepresentable {
    @Binding var sessionError: String?

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        arView.automaticallyConfigureSession = false
        arView.session.delegate = context.coordinator

        arView.environment.lighting.intensityExponent = 1.0
        arView.renderOptions.insert(.disableMotionBlur)

        startSession(on: arView)
        return arView
    }

    func updateUIView(_ uiView: ARView, context: Context) {}

    func startSession(on arView: ARView) {
        guard ARWorldTrackingConfiguration.isSupported else { return }
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal, .vertical]
        if ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh) {
            config.sceneReconstruction = .mesh
        }
        arView.session.run(config, options: [.resetTracking, .removeExistingAnchors])
    }

    final class Coordinator: NSObject, ARSessionDelegate {
        private let parent: ARViewContainer
        init(_ parent: ARViewContainer) { self.parent = parent }

        func session(_ session: ARSession, didFailWithError error: Error) {
            parent.sessionError = error.localizedDescription
            print("[AR] didFailWithError:", error)
        }

        func sessionWasInterrupted(_ session: ARSession) {
            print("[AR] session interrupted")
        }

        func sessionInterruptionEnded(_ session: ARSession) {
            print("[AR] interruption ended — recommend resetting tracking if needed")
        }
    }
}

private struct UnsupportedView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "arkit")
                .font(.system(size: 44))
            Text("AR Not Supported on This Device")
                .font(.headline)
            Text("Try on a newer iPhone or iPad with ARKit support.")
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding()
    }
}

private struct ErrorOverlay: View {
    let title: String
    let message: String
    var body: some View {
        VStack {
            Spacer()
            VStack(spacing: 8) {
                Text(title).font(.headline)
                Text(message)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding()
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
            .padding()
        }
        .transition(.opacity)
        .animation(.easeInOut, value: message)
    }
}
