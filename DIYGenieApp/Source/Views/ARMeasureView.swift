import SwiftUI
import ARKit

struct ARMeasureView: UIViewRepresentable {
    var onMeasureUpdate: (_ inchesX: Double, _ inchesY: Double) -> Void

    func makeUIView(context: Context) -> ARSCNView {
        let view = ARSCNView(frame: .zero)
        view.session.delegate = context.coordinator
        view.autoenablesDefaultLighting = true
        view.automaticallyUpdatesLighting = true

        let tap = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        view.addGestureRecognizer(tap)

        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal, .vertical]
        view.session.run(config)

        return view
    }

    func updateUIView(_ uiView: ARSCNView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onMeasureUpdate: onMeasureUpdate)
    }

    // MARK: - Coordinator
    class Coordinator: NSObject, ARSessionDelegate {
        var onMeasureUpdate: (_ inchesX: Double, _ inchesY: Double) -> Void
        private var firstPoint: simd_float3?

        init(onMeasureUpdate: @escaping (_ inchesX: Double, _ inchesY: Double) -> Void) {
            self.onMeasureUpdate = onMeasureUpdate
        }

        @objc func handleTap(_ sender: UITapGestureRecognizer) {
            guard let sceneView = sender.view as? ARSCNView else { return }
            let tapLocation = sender.location(in: sceneView)

            // ✅ Use new API instead of deprecated hitTest
            guard let query = sceneView.raycastQuery(from: tapLocation,
                                                     allowing: .estimatedPlane,
                                                     alignment: .any),
                  let result = sceneView.session.raycast(query).first else {
                return
            }

            let worldPos = simd_make_float3(result.worldTransform.columns.3)

            if let first = firstPoint {
                let dx = Float(worldPos.x - first.x)
                let dy = Float(worldPos.y - first.y)
                let dz = Float(worldPos.z - first.z)

                let distanceMeters = sqrt(dx * dx + dy * dy + dz * dz)
                let distanceInches = Double(distanceMeters * 39.3701)

                onMeasureUpdate(distanceInches, distanceInches)
                firstPoint = nil
            } else {
                firstPoint = worldPos
            }
        }
    }
}
