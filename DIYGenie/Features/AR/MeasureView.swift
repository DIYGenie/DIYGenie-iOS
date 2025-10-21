// Features/AR/MeasureView.swift

import SwiftUI
import ARKit
import SceneKit

/// Fallback AR measuring tool for non-LiDAR devices.
/// Tap to add points; lines render between taps; we compute segment lengths in meters.
struct MeasureView: UIViewControllerRepresentable {
    let onComplete: (RoomPlanSummary?) -> Void

    func makeUIViewController(context: Context) -> MeasureVC {
        let vc = MeasureVC()
        vc.onComplete = onComplete
        return vc
    }

    func updateUIViewController(_ uiViewController: MeasureVC, context: Context) { }
}

final class MeasureVC: UIViewController, ARSCNViewDelegate {
    var onComplete: ((RoomPlanSummary?) -> Void)?

    private let sceneView = ARSCNView(frame: .zero)
    private var points: [SCNVector3] = []
    private var segments: [Double] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black

        sceneView.translatesAutoresizingMaskIntoConstraints = false
        sceneView.delegate = self
        sceneView.automaticallyUpdatesLighting = true
        view.addSubview(sceneView)
        NSLayoutConstraint.activate([
            sceneView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            sceneView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            sceneView.topAnchor.constraint(equalTo: view.topAnchor),
            sceneView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        // Tap recognizer
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        sceneView.addGestureRecognizer(tap)

        // Done button
        let done = UIButton(type: .system)
        done.setTitle("Done", for: .normal)
        done.titleLabel?.font = .boldSystemFont(ofSize: 17)
        done.backgroundColor = .systemBackground.withAlphaComponent(0.8)
        done.layer.cornerRadius = 10
        done.addTarget(self, action: #selector(finish), for: .touchUpInside)
        done.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(done)
        NSLayoutConstraint.activate([
            done.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            done.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            done.heightAnchor.constraint(equalToConstant: 44),
            done.widthAnchor.constraint(equalToConstant: 120)
        ])
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal, .vertical]
        sceneView.session.run(config, options: [.resetTracking, .removeExistingAnchors])
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sceneView.session.pause()
    }

    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        let loc = gesture.location(in: sceneView)
        let results = sceneView.raycastQuery(from: loc, allowing: .estimatedPlane, alignment: .any)
            .flatMap { sceneView.session.raycast($0) } ?? []

        guard let hit = results.first else { return }
        let pos = SCNVector3(hit.worldTransform.columns.3.x,
                             hit.worldTransform.columns.3.y,
                             hit.worldTransform.columns.3.z)

        // Place a small sphere at the point
        let sphere = SCNSphere(radius: 0.005)
        sphere.firstMaterial?.diffuse.contents = UIColor.systemYellow
        let node = SCNNode(geometry: sphere)
        node.position = pos
        sceneView.scene.rootNode.addChildNode(node)

        // Connect with previous point if exists
        if let last = points.last {
            let line = lineNode(from: last, to: pos)
            sceneView.scene.rootNode.addChildNode(line)
            segments.append(distance(from: last, to: pos))
        }
        points.append(pos)
    }

    @objc private func finish() {
        // Very rough polygon area (projected on XZ plane) if user closed the loop
        let area = polygonAreaM2(pointsXZ: points.map { CGPoint(x: CGFloat($0.x), y: CGFloat($0.z)) })
        let summary = RoomPlanSummary(totalArea: area, wallCount: nil, openingsCount: nil, segments: segments)
        onComplete?(summary)
        dismiss(animated: true)
    }

    // MARK: - Helpers

    private func lineNode(from: SCNVector3, to: SCNVector3) -> SCNNode {
        let source = SCNGeometrySource(vertices: [from, to])
        let indices: [Int32] = [0, 1]
        let element = SCNGeometryElement(indices: indices, primitiveType: .line)
        let geom = SCNGeometry(sources: [source], elements: [element])
        geom.firstMaterial?.diffuse.contents = UIColor.systemCyan
        return SCNNode(geometry: geom)
    }

    private func distance(from a: SCNVector3, to b: SCNVector3) -> Double {
        let dx = Double(b.x - a.x)
        let dy = Double(b.y - a.y)
        let dz = Double(b.z - a.z)
        return sqrt(dx*dx + dy*dy + dz*dz)
    }

    /// Shoelace formula on projected XZ polygon (meters²). Returns nil if <3 points.
    private func polygonAreaM2(pointsXZ: [CGPoint]) -> Double? {
        guard pointsXZ.count >= 3 else { return nil }
        var sum = 0.0
        for i in 0..<pointsXZ.count {
            let j = (i + 1) % pointsXZ.count
            sum += Double(pointsXZ[i].x * pointsXZ[j].y - pointsXZ[j].x * pointsXZ[i].y)
        }
        return abs(sum) * 0.5
    }
}

// ✅ Ready to Build
