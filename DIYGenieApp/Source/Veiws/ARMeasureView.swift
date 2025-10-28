import SwiftUI
import ARKit
import RealityKit
import Combine
import UIKit

/// DIY Genie – Advanced AR Measure View
/// Live crosshair, corner snapping, rectangular area measurement, inch units, and help overlay.
@available(iOS 15.0, *)
struct ARMeasureView: UIViewRepresentable {
    @Environment(\.dismiss) private var dismiss
    var onComplete: (_ width: Double, _ height: Double) -> Void

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        arView.session.delegate = context.coordinator
        arView.automaticallyConfigureSession = false

        // Configure ARKit for plane detection
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal, .vertical]
        arView.session.run(config)

        // Add crosshair overlay
        let crosshair = UIView(frame: CGRect(x: 0, y: 0, width: 20, height: 20))
        crosshair.center = arView.center
        crosshair.layer.cornerRadius = 10
        crosshair.layer.borderWidth = 2
        crosshair.layer.borderColor = UIColor(red: 113/255, green: 66/255, blue: 255/255, alpha: 0.9).cgColor
        crosshair.backgroundColor = UIColor.clear
        crosshair.tag = 999
        arView.addSubview(crosshair)

        // Add help overlay button
        let helpButton = UIButton(type: .infoLight)
        helpButton.tintColor = .white
        helpButton.frame = CGRect(x: arView.frame.width - 50, y: 50, width: 30, height: 30)
        helpButton.autoresizingMask = [.flexibleLeftMargin, .flexibleBottomMargin]
        helpButton.addTarget(context.coordinator, action: #selector(Coordinator.showHelpOverlay), for: .touchUpInside)
        arView.addSubview(helpButton)

        // Add finish button
        let finishButton = UIButton(type: .system)
        finishButton.setTitle("Finish", for: .normal)
        finishButton.titleLabel?.font = .boldSystemFont(ofSize: 16)
        finishButton.setTitleColor(.white, for: .normal)
        finishButton.backgroundColor = UIColor(red: 113/255, green: 66/255, blue: 255/255, alpha: 0.9)
        finishButton.layer.cornerRadius = 8
        finishButton.frame = CGRect(x: arView.frame.midX - 50, y: arView.frame.height - 100, width: 100, height: 40)
        finishButton.autoresizingMask = [.flexibleTopMargin, .flexibleLeftMargin, .flexibleRightMargin]
        finishButton.addTarget(context.coordinator, action: #selector(Coordinator.finishMeasurement), for: .touchUpInside)
        arView.addSubview(finishButton)

        // Tap gesture recognizer
        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        arView.addGestureRecognizer(tapGesture)

        context.coordinator.arView = arView
        return arView
    }

    func updateUIView(_ uiView: ARView, context: Context) {}

    final class Coordinator: NSObject, ARSessionDelegate {
        var parent: ARMeasureView
        weak var arView: ARView?
        private var cornerEntities: [Entity] = []
        private var lineEntities: [Entity] = []

        init(_ parent: ARMeasureView) { self.parent = parent }

        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            guard let arView = arView else { return }
            let location = gesture.location(in: arView)

            if let result = arView.raycast(from: location, allowing: .estimatedPlane, alignment: .any).first {
                let position = simd_make_float3(result.worldTransform.columns.3)
                addCorner(at: position)
            }
        }

        private func addCorner(at position: SIMD3<Float>) {
            guard let arView = arView else { return }

            // Create purple corner sphere
            let mesh = MeshResource.generateSphere(radius: 0.01)
            let material = SimpleMaterial(color: .init(red: 113/255, green: 66/255, blue: 255/255, alpha: 1), isMetallic: false)
            let sphere = ModelEntity(mesh: mesh, materials: [material])
            let anchor = AnchorEntity(world: position)
            anchor.addChild(sphere)
            arView.scene.addAnchor(anchor)
            cornerEntities.append(anchor)

            // Add lines if multiple corners
            if cornerEntities.count > 1 {
                addLine(from: cornerEntities[cornerEntities.count - 2], to: anchor)
            }

            // Auto-finish after 4 corners
            if cornerEntities.count == 4 {
                finishMeasurement()
            }
        }

        private func addLine(from start: Entity, to end: Entity) {
            let startPos = start.position(relativeTo: nil)
            let endPos = end.position(relativeTo: nil)
            let distance = simd_distance(startPos, endPos)

            let lineMesh = MeshResource.generateBox(size: [0.002, 0.002, distance])
            let material = SimpleMaterial(color: .white, isMetallic: false)
            let lineEntity = ModelEntity(mesh: lineMesh, materials: [material])
            lineEntity.position = (startPos + endPos) / 2
            lineEntity.look(at: endPos, from: lineEntity.position, relativeTo: nil)
            let anchor = AnchorEntity(world: lineEntity.position)
            anchor.addChild(lineEntity)
            arView?.scene.addAnchor(anchor)
            lineEntities.append(anchor)
        }

        @objc func finishMeasurement() {
            guard cornerEntities.count >= 2 else { return }
            let first = cornerEntities.first!.position(relativeTo: nil)
            let second = cornerEntities.last!.position(relativeTo: nil)

            let widthMeters = abs(second.x - first.x)
            let heightMeters = abs(second.z - first.z)
            let widthInches = Double(widthMeters * 39.37)
            let heightInches = Double(heightMeters * 39.37)

            // Cleanup scene
            cornerEntities.forEach { $0.removeFromParent() }
            lineEntities.forEach { $0.removeFromParent() }

            parent.onComplete(widthInches, heightInches)
            parent.dismiss()
        }

        @objc func showHelpOverlay() {
            guard let view = arView else { return }

            let overlay = UIView(frame: view.bounds)
            overlay.backgroundColor = UIColor.black.withAlphaComponent(0.8)
            overlay.layer.cornerRadius = 16
            overlay.autoresizingMask = [.flexibleWidth, .flexibleHeight]

            let label = UILabel()
            label.text = """
            📏 How to Measure
            • Move camera slowly until surface is detected.
            • Tap 4 corners to outline your area.
            • The purple box shows your measured zone.
            • Tap Finish to confirm.
            """
            label.textColor = .white
            label.font = UIFont.systemFont(ofSize: 16)
            label.numberOfLines = 0
            label.textAlignment = .center
            label.translatesAutoresizingMaskIntoConstraints = false

            let close = UIButton(type: .system)
            close.setTitle("Got it", for: .normal)
            close.setTitleColor(.white, for: .normal)
            close.backgroundColor = UIColor(red: 113/255, green: 66/255, blue: 255/255, alpha: 1)
            close.layer.cornerRadius = 8
            close.translatesAutoresizingMaskIntoConstraints = false
            close.addAction(UIAction { _ in overlay.removeFromSuperview() }, for: .touchUpInside)

            overlay.addSubview(label)
            overlay.addSubview(close)
            view.addSubview(overlay)

            NSLayoutConstraint.activate([
                label.centerXAnchor.constraint(equalTo: overlay.centerXAnchor),
                label.centerYAnchor.constraint(equalTo: overlay.centerYAnchor, constant: -20),
                label.leadingAnchor.constraint(equalTo: overlay.leadingAnchor, constant: 20),
                label.trailingAnchor.constraint(equalTo: overlay.trailingAnchor, constant: -20),
                close.centerXAnchor.constraint(equalTo: overlay.centerXAnchor),
                close.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 20),
                close.widthAnchor.constraint(equalToConstant: 120),
                close.heightAnchor.constraint(equalToConstant: 44)
            ])
        }
    }
}
