// Features/AR/RoomPlanView.swift

import SwiftUI
import ARKit

// MARK: - Shared Summary
public struct RoomPlanSummary: Codable, Equatable {
    public var totalArea: Double?      // m² (approx from floors)
    public var wallCount: Int?
    public var openingsCount: Int?
    public var segments: [Double] = [] // used by fallback MeasureView
}

@MainActor
struct RoomPlanView: View {
    let onComplete: (RoomPlanSummary?) -> Void

    var body: some View {
        if #available(iOS 16.0, *), RoomPlanAvailability.isSupported {
            _RoomPlanCapture(onComplete: onComplete)
                .ignoresSafeArea()
        } else {
            VStack(spacing: 16) {
                Image(systemName: "arkit").font(.system(size: 48, weight: .semibold))
                Text("RoomPlan not available").font(.title3).bold()
                Text("This device doesn’t support LiDAR RoomPlan. Use the fallback Measure tool instead.")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                Button("Use Fallback Measure") { onComplete(nil) }
                    .buttonStyle(.borderedProminent)
            }
            .padding()
        }
    }
}

#if canImport(RoomPlan)
import RoomPlan

@available(iOS 16.0, *)
private struct _RoomPlanCapture: UIViewControllerRepresentable {
    let onComplete: (RoomPlanSummary?) -> Void

    func makeUIViewController(context: Context) -> RPViewController {
        let vc = RPViewController()
        vc.onComplete = onComplete
        return vc
    }

    func updateUIViewController(_ uiViewController: RPViewController, context: Context) {}
}

// MARK: - Controller hosting RoomCaptureView
@available(iOS 16.0, *)
final class RPViewController: UIViewController, RoomCaptureViewDelegate {
    let captureView = RoomCaptureView(frame: .zero)

    var onComplete: ((RoomPlanSummary?) -> Void)?
    private var latestRoom: CapturedRoom?
    private var isRunning = false

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black

        captureView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(captureView)
        NSLayoutConstraint.activate([
            captureView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            captureView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            captureView.topAnchor.constraint(equalTo: view.topAnchor),
            captureView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        captureView.delegate = self

        // Finish button overlay
        let done = UIButton(type: .system)
        done.setTitle("Finish", for: .normal)
        done.titleLabel?.font = .boldSystemFont(ofSize: 17)
        done.backgroundColor = .systemBackground.withAlphaComponent(0.85)
        done.layer.cornerRadius = 10
        done.translatesAutoresizingMaskIntoConstraints = false
        done.addTarget(self, action: #selector(finishTapped), for: .touchUpInside)
        view.addSubview(done)
        NSLayoutConstraint.activate([
            done.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            done.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            done.heightAnchor.constraint(equalToConstant: 44),
            done.widthAnchor.constraint(equalToConstant: 120)
        ])
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        guard !isRunning else { return }
        // Use the view's built-in session (get-only) and run it
        captureView.captureSession.run(configuration: RoomCaptureSession.Configuration())
        isRunning = true
    }

    // MARK: - Finish
    @objc private func finishTapped() {
        let summary = latestRoom.map { summarize(scene: $0) }
        onComplete?(summary)
        dismiss(animated: true)
    }

    // MARK: - RoomCaptureViewDelegate
    /// Incremental room updates
    func captureView(_ captureView: RoomCaptureView, didUpdate room: CapturedRoom) {
        latestRoom = room
    }

    func captureView(_ captureView: RoomCaptureView, didPresent error: Error) {
        onComplete?(nil)
        dismiss(animated: true)
    }

    // MARK: - Summarize a captured room
    private func summarize(scene: CapturedRoom) -> RoomPlanSummary {
        // Floors-based area (sum of x * z for each floor surface, iOS 17+)
        var areaFromFloors: Double? = nil
        if #available(iOS 17.0, *) {
            let floors = scene.floors
            if !floors.isEmpty {
                areaFromFloors = floors.reduce(0.0) { sum, f in
                    sum + Double(f.dimensions.x * f.dimensions.z)
                }
            }
        }

        // Fallback counts for walls and openings if available
        var wallCount: Int? = nil
        var openingsCount: Int? = nil
        if #available(iOS 17.0, *) {
            wallCount = scene.walls.count
            openingsCount = scene.openings.count
        }

        // Build the summary; segments left empty for now (used by fallback MeasureView)
        return RoomPlanSummary(
            totalArea: areaFromFloors,
            wallCount: wallCount,
            openingsCount: openingsCount,
            segments: []
        )
    }
}
#endif
// MARK: - Capability Check
@available(iOS 16.0, *)
enum RoomPlanAvailability {
    static var isSupported: Bool {
        ARWorldTrackingConfiguration.supportsFrameSemantics(.sceneDepth) && ARWorldTrackingConfiguration.isSupported
    }
}

// ✅ Ready to Build
