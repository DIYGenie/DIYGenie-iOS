import SwiftUI
import ARKit
import RealityKit

/// A smoother, multi-point AR ruler with live distance updates.
@available(iOS 14.0, *)
struct ARMeasureView: UIViewRepresentable {
    @Environment(\.dismiss) private var dismiss
    var onComplete: ([Double]) -> Void   // Returns list of all segment lengths

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        arView.session.delegate = context.coordinator

        // Configure ARKit
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal, .vertical]
        arView.session.run(config, options: [.removeExistingAnchors, .resetTracking])

        // Add tap gesture
        let tap = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        arView.addGestureRecognizer(tap)
        context.coordinator.arView = arView

        return arView
    }

    func updateUIView(_ uiView: ARView, context: Context) {}

    final class Coordinator: NSObject, ARSessionDelegate {
        var parent: ARMeasureView
        weak var arView: ARView?
        private var points: [SIMD3<Float>] = []
        private var lines: [Entity] = []

        init(_ parent: ARMeasureView) {
            self.parent = parent
        }

        @objc func handleTap(_ sender: UITapGestureRecognizer) {
            guard let arView = arView else { return }
            let location = sender.location(in: arView)

            if let result = arView.raycast(from: location, allowing: .estimatedPlane, alignment: .any).first {
                let position = result.worldTransform.translation
                points.append(position)
                addSphere(at: position)

                if points.count > 1 {
                    let distance = distanceBetween(points[points.count - 2], points.last!)
                    addLine(from: points[points.count - 2], to: points.last!)
                    showDistanceText(distance, at: points.last!)

                    // Auto-complete if more than 2 points (can change if desired)
                    if points.count >= 2 {
                        parent.onComplete(pointsToInches())
                        parent.dismiss()
                    }
                }
            }
        }

        func distanceBetween(_ start: SIMD3<Float>, _ end: SIMD3<Float>) -> Float {
            simd_distance(start, end)
        }

        func pointsToInches() -> [Double] {
            return zip(points.dropLast(), points.dropFirst()).map { start, end in
                Double(simd_distance(start, end)) * 39.37 // meters → inches
            }
        }

        private func addSphere(at position: SIMD3<Float>) {
            let sphere = ModelEntity(
                mesh: .generateSphere(radius: 0.005),
                materials: [SimpleMaterial(color: .purple, isMetallic: false)]
            )
            let anchor = AnchorEntity(world: position)
            anchor.addChild(sphere)
            arView?.scene.addAnchor(anchor)
        }


        private func addLine(from start: SIMD3<Float>, to end: SIMD3<Float>) {
            var lineMesh = MeshResource.generateBox(size: [0.002, 0.002, simd_distance(start, end)])
            let line = ModelEntity(mesh: lineMesh, materials: [SimpleMaterial(color: .purple, isMetallic: false)])
            line.look(at: end, from: start, relativeTo: nil)
            let mid = (start + end) / 2
            let anchor = AnchorEntity(world: mid)
            anchor.addChild(line)
            arView?.scene.addAnchor(anchor)
        }

        private func showDistanceText(_ distance: Float, at position: SIMD3<Float>) {
            let inches = distance * 39.37
            let text = MeshResource.generateText(String(format: "%.1f in", inches), extrusionDepth: 0.002, font: .systemFont(ofSize: 0.05))
            let textEntity = ModelEntity(mesh: text, materials: [SimpleMaterial(color: .white, isMetallic: false)])
            let anchor = AnchorEntity(world: position)
            anchor.addChild(textEntity)
            arView?.scene.addAnchor(anchor)
        }
    }
}

private extension simd_float4x4 {
    var translation: SIMD3<Float> {
        let translation = self.columns.3
        return [translation.x, translation.y, translation.z]
    }
}
