//
//  ARMeasureView.swift
//  DIYGenieApp
//
//  Live AR measuring: tap to place points, see distance, Done/ Clear controls.
//

import SwiftUI
import RealityKit
import ARKit
import AVFoundation

extension Notification.Name {
    static let ARMeasureClear = Notification.Name("ARMeasureClear")
}

struct ARMeasureView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var cameraDenied = false
    @State private var sessionError: String?
    @State private var latestDistanceMeters: Float?

    var onMeasure: ((Float) -> Void)?    // returns meters

    var body: some View {
        ZStack {
            if ARWorldTrackingConfiguration.isSupported {
                ARMeasureContainer(sessionError: $sessionError, latestDistanceMeters: $latestDistanceMeters)
                    .ignoresSafeArea()
            } else {
                UnsupportedView()
            }

            // Top bar
            VStack(spacing: 8) {
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28, weight: .semibold))
                            .padding(10)
                    }

                    Spacer()

                    if let m = latestDistanceMeters {
                        DistancePill(meters: m)
                    }
                }
                .padding(.horizontal, 8)

                Spacer()

                // Bottom controls
                HStack(spacing: 12) {
                    Button {
                        NotificationCenter.default.post(name: .ARMeasureClear, object: nil)
                        latestDistanceMeters = nil
                    } label: {
                        Label("Clear", systemImage: "trash")
                            .padding(.vertical, 10)
                            .padding(.horizontal, 14)
                            .background(.ultraThinMaterial, in: Capsule())
                    }

                    Spacer()

                    Button {
                        if let m = latestDistanceMeters {
                            onMeasure?(m)
                        }
                        dismiss()
                    } label: {
                        Label("Done", systemImage: "checkmark.circle.fill")
                            .padding(.vertical, 10)
                            .padding(.horizontal, 14)
                            .background(Color.accentColor, in: Capsule())
                            .foregroundColor(.white)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 20)
            }

            if cameraDenied {
                ErrorOverlay(
                    title: "Camera Access Needed",
                    message: "Enable camera in Settings → Privacy → Camera to use AR measuring."
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

// MARK: - UIViewRepresentable

private struct ARMeasureContainer: UIViewRepresentable {
    @Binding var sessionError: String?
    @Binding var latestDistanceMeters: Float?

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIView(context: Context) -> ARView {
        let view = ARView(frame: .zero)
        view.automaticallyConfigureSession = false
        view.session.delegate = context.coordinator
        if #available(iOS 15.0, *) {
            view.environment.lighting.intensityExponent = 1.0
        }
        view.renderOptions.insert(.disableMotionBlur)

        // Tap gesture: add/measure points
        let tap = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        view.addGestureRecognizer(tap)

        // Listen for Clear
        NotificationCenter.default.addObserver(context.coordinator, selector: #selector(Coordinator.handleClear), name: .ARMeasureClear, object: nil)

        context.coordinator.attach(to: view)
        startSession(on: view)
        return view
    }

    func updateUIView(_ uiView: ARView, context: Context) {}

    func startSession(on view: ARView) {
        guard ARWorldTrackingConfiguration.isSupported else { return }
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal, .vertical]
        if ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh) {
            config.sceneReconstruction = .mesh
        }
        view.session.run(config, options: [.resetTracking, .removeExistingAnchors])
    }

    final class Coordinator: NSObject, ARSessionDelegate {
        private weak var arView: ARView?
        private var points: [SIMD3<Float>] = []
        private var lineEntity: ModelEntity?
        private var dotEntities: [ModelEntity] = []
        private var parent: ARMeasureContainer

        init(_ parent: ARMeasureContainer) { self.parent = parent }

        func attach(to view: ARView) { self.arView = view }

        @objc func handleClear() {
            points.removeAll()
            removeEntities()
            parent.latestDistanceMeters = nil
        }

        func removeEntities() {
            lineEntity?.removeFromParent()
            lineEntity = nil
            dotEntities.forEach { $0.removeFromParent() }
            dotEntities.removeAll()
        }

        @objc func handleTap(_ recognizer: UITapGestureRecognizer) {
            guard let view = arView else { return }
            let location = recognizer.location(in: view)

            // 1) Raycast to surface
            let results = view.raycast(from: location, allowing: .estimatedPlane, alignment: .any)
            guard let result = results.first else { return }
            let worldPos = SIMD3<Float>(result.worldTransform.columns.3.x,
                                        result.worldTransform.columns.3.y,
                                        result.worldTransform.columns.3.z)

            addDot(at: worldPos)

            points.append(worldPos)
            if points.count >= 2 {
                let a = points[points.count - 2]
                let b = points[points.count - 1]
                let d = distance(a, b)
                parent.latestDistanceMeters = d
                drawLine(from: a, to: b)
            }
        }

        func addDot(at position: SIMD3<Float>) {
            let sphere = MeshResource.generateSphere(radius: 0.005)
            let mat = SimpleMaterial(color: .white, isMetallic: false)
            let dot = ModelEntity(mesh: sphere, materials: [mat])
            let anchor = AnchorEntity(world: position)
            anchor.addChild(dot)
            arView?.scene.addAnchor(anchor)
            dotEntities.append(dot)
        }

        func drawLine(from: SIMD3<Float>, to: SIMD3<Float>) {
            // Remove old line
            lineEntity?.removeFromParent()

            // Create a thin cylinder between points
            let vector = to - from
            let length = simd_length(vector)
            guard length > 0.0001 else { return }
            let mid = (from + to) / 2.0

            let cylinder = MeshResource.generateBox(size: [0.002, 0.002, length])
            let material = SimpleMaterial(color: .yellow, isMetallic: false)
            let model = ModelEntity(mesh: cylinder, materials: [material])

            // Orient to match the vector
            let zAxis = SIMD3<Float>(0, 0, 1)
            let axis = simd_normalize(simd_cross(zAxis, simd_normalize(vector)))
            let angle = acos(simd_dot(simd_normalize(vector), zAxis))
            model.orientation = simd_quatf(angle: angle, axis: axis)
            model.position = mid

            let anchor = AnchorEntity(world: mid)
            anchor.addChild(model)
            arView?.scene.addAnchor(anchor)
            lineEntity = model
        }

        // Session delegates
        func session(_ session: ARSession, didFailWithError error: Error) {
            parent.sessionError = error.localizedDescription
        }
        func sessionWasInterrupted(_ session: ARSession) {}
        func sessionInterruptionEnded(_ session: ARSession) {}
    }
}

// MARK: - UI helpers

private struct DistancePill: View {
    let meters: Float
    var feetInches: String {
        let totalInches = meters * 39.3701
        let feet = Int(totalInches / 12.0)
        let inches = totalInches.truncatingRemainder(dividingBy: 12.0)
        return "\(feet)′ \(String(format: "%.1f", inches))″"
    }
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "ruler")
            Text(feetInches)
        }
        .font(.subheadline)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(.ultraThinMaterial, in: Capsule())
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
