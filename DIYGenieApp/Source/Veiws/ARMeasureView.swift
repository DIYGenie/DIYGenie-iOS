import SwiftUI
import ARKit
import RealityKit

/// A simple AR measurement view that lets the user tap two points on a detected plane
/// and returns the distance in inches.
@available(iOS 14.0, *)
struct ARMeasureView: UIViewRepresentable {
    @Environment(\.dismiss) private var dismiss
    var onComplete: (Double) -> Void

    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        arView.session.delegate = context.coordinator

        // Configure ARKit for plane detection
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal, .vertical]
        arView.session.run(configuration, options: [.removeExistingAnchors, .resetTracking])

        // Enable tap gesture
        let tapGesture = UITapGestureRecognizer(target: context.coordinator,
                                                action: #selector(Coordinator.handleTap(_:)))
        arView.addGestureRecognizer(tapGesture)

        context.coordinator.arView = arView
        return arView
    }

    func updateUIView(_ uiView: ARView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    final class Coordinator: NSObject, ARSessionDelegate {
        var parent: ARMeasureView
        weak var arView: ARView?
        private var firstPoint: SIMD3<Float>?
        private var dotEntities: [ModelEntity] = []

        init(parent: ARMeasureView) {
            self.parent = parent
        }

        /// Handle a tap: place a marker at the tapped location and measure when two points exist.
        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            guard let arView = arView else { return }
            let location = gesture.location(in: arView)
            if let result = arView.raycast(from: location, allowing: .existingPlaneGeometry, alignment: .any).first {
                let position = result.worldTransform.translation
                placeDot(at: position)

                if let first = firstPoint {
                    // Compute distance in meters
                    let distanceMeters = simd_distance(first, position)
                    // Convert to inches (1 meter = 39.3701 inches)
                    let distanceInches = Double(distanceMeters) * 39.3701
                    parent.onComplete(distanceInches)
                    // Clean up anchors and dots
                    arView.scene.anchors.removeAll()
                    dotEntities.removeAll()
                    firstPoint = nil
                    parent.dismiss() // close the view
                } else {
                    firstPoint = position
                }
            }
        }

        private func placeDot(at position: SIMD3<Float>) {
            guard let arView = arView else { return }
            let dot = ModelEntity(mesh: .generateSphere(radius: 0.003), materials: [SimpleMaterial(color: .purple, isMetallic: false)])
            let anchor = AnchorEntity(world: position)
            anchor.addChild(dot)
            arView.scene.addAnchor(anchor)
            dotEntities.append(dot)
        }
    }
}

private extension simd_float4x4 {
    /// Extract translation vector from a 4x4 transform matrix.
    var translation: SIMD3<Float> {
        return [columns.3.x, columns.3.y, columns.3.z]
    }
}
