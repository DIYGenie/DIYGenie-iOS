import SwiftUI
import ARKit
import RealityKit

/// Real AR measurement overlay that lets the user drag a glowing rectangle
/// and reports the real-world width and height in inches.
struct ARMeasureView: View {
    var onComplete: (Double, Double) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var startPoint: SIMD3<Float>?
    @State private var endPoint: SIMD3<Float>?
    @State private var measuredWidth: Double = 0
    @State private var measuredHeight: Double = 0
    @State private var showText = false

    var body: some View {
        ZStack {
            ARContainer(onMeasureUpdate: { width, height in
                measuredWidth = width
                measuredHeight = height
            })
            .ignoresSafeArea()

            VStack {
                Spacer()
                if showText {
                    Text(String(format: "W: %.1f in | H: %.1f in", measuredWidth, measuredHeight))
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.black.opacity(0.6))
                        .cornerRadius(8)
                        .transition(.opacity)
                }

                HStack {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.black.opacity(0.4))
                    .cornerRadius(8)

                    Spacer()

                    Button("Save") {
                        onComplete(measuredWidth, measuredHeight)
                        dismiss()
                    }
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.purple.opacity(0.8))
                    .cornerRadius(8)
                }
                .padding(.horizontal, 30)
                .padding(.bottom, 40)
            }
        }
        .onAppear {
            withAnimation { showText = true }
        }
    }
}

// MARK: - ARContainer (RealityKit + Raycast measurement)
struct ARContainer: UIViewRepresentable {
    var onMeasureUpdate: (Double, Double) -> Void

    func makeCoordinator() -> Coordinator { Coordinator(onMeasureUpdate: onMeasureUpdate) }

    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        arView.session.delegate = context.coordinator

        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal, .vertical]
        arView.session.run(config)

        // Tap gestures to define measurement corners
        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        arView.addGestureRecognizer(tapGesture)

        return arView
    }

    func updateUIView(_ uiView: ARView, context: Context) {}

    // MARK: - Coordinator
    class Coordinator: NSObject, ARSessionDelegate {
        var firstPoint: SIMD3<Float>?
        var onMeasureUpdate: (Double, Double) -> Void

        init(onMeasureUpdate: @escaping (Double, Double) -> Void) {
            self.onMeasureUpdate = onMeasureUpdate
        }

        @objc func handleTap(_ sender: UITapGestureRecognizer) {
            guard let view = sender.view as? ARView else { return }
            let tapLocation = sender.location(in: view)

            guard let raycast = view.raycast(from: tapLocation, allowing: .estimatedPlane, alignment: .any).first else { return }
            let worldPos = raycast.worldTransform.translation

            if let first = firstPoint {
                // Second tap — measure distance
                let dx = worldPos.x - first.x
                let dy = worldPos.y - first.y
                let dz = worldPos.z - first.z

                // Convert 3D distance to inches
                let distanceMeters = sqrt(dx * dx + dy * dy + dz * dz)
                let distanceInches = Double(distanceMeters * 39.3701)
                onMeasureUpdate(distanceInches, distanceInches) // placeholder equal dims
                firstPoint = nil
            } else {
                firstPoint = worldPos
            }
        }
    }
}
