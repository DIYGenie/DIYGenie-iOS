// Features/AR/RoomPlanView.swift

import SwiftUI
import ARKit

// MARK: - Shared Summary Model (used by RoomPlan and fallback)
public struct RoomPlanSummary: Codable, Equatable {
    public var totalArea: Double?      // m² (approx; nil for now)
    public var wallCount: Int?
    public var openingsCount: Int?
    public var segments: [Double] = [] // meters (used by fallback MeasureView)
}

// MARK: - SwiftUI Wrapper
@MainActor
struct RoomPlanView: View {
    let onComplete: (RoomPlanSummary?) -> Void

    var body: some View {
        if #available(iOS 16.0, *), RoomPlanAvailability.isSupported {
            _RoomPlanCapture(onComplete: onComplete)
                .ignoresSafeArea()
        } else {
            VStack(spacing: 16) {
                Image(systemName: "arkit")
                    .font(.system(size: 48, weight: .semibold))
                Text("RoomPlan not available")
                    .font(.title3).bold()
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

// MARK: - UIViewControllerRepresentable wrapper
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

// MARK: - Controller hosting RoomCaptureView + delegate
@available(iOS 16.0, *)
final class RPViewController: UIViewController, RoomCaptureViewDelegate {
    // Session & view
    let captureSession = RoomCaptureSession()
    let captureView = RoomCaptureView(frame: .zero)

    // Output
    var onComplete: ((RoomPlanSummary?) -> Void)?

    // State
    private var latestRoom: CapturedRoom?
    private var isRunning = false

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black

        // Add and constrain captureView
        captureView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(captureView)
        NSLayoutConstraint.activate([
            captureView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            captureView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            captureView.topAnchor.constraint(equalTo: view.topAnchor),
            captureView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        // Wire session + delegate
        captureView.captureSession = captureSession
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
        captureSession.run(configuration: RoomCaptureSession.Configuration())
        isRunning = true
    }

    // MARK: - Finish
    @objc private func finishTapped() {
        let summary = latestRoom.map(summarize(scene:))
        onComplete?(summary)
        dismiss(animated: true)
    }

    // MARK: - RoomCaptureViewDelegate
    /// Called frequently with incremental room updates.
    func captureView(_ captureView: RoomCaptureView, didUpdate room: CapturedRoom) {
        latestRoom = room
    }

    /// Called on state changes; keep final snapshot.
    func captureView(_ captureView: RoomCaptureView,
                     didUpdate captureState: RoomCaptureSession.CaptureState) {
        if case .final(let room) = captureState {
            latestRoom = room
        }
    }

    func captureView(_ captureView: RoomCaptureView, didPresent error: Error) {
        onComplete?(nil)
        dismiss(animated: true)
    }

    // MARK: - Summarize a captured room
    private func summarize(scene: CapturedRoom) -> RoomPlanSummary {
        let walls = scene.walls.count
        let openings = scene.doors.count + scene.openings.count + scene.windows.count

        // Area: not all SDK versions expose floor polygons reliably.
        // We keep nil for now; can compute from wall footprint later if needed.
        return RoomPlanSummary(
            totalArea: nil,
            wallCount: walls,
            openingsCount: openings,
            segments: []
        )
    }
}
#endif

// MARK: - Capability Check
@available(iOS 16.0, *)
enum RoomPlanAvailability {
    static var isSupported: Bool {
        // RoomPlan requires sceneDepth (LiDAR) support.
        ARWorldTrackingConfiguration.supportsFrameSemantics(.sceneDepth)
    }
}

// ✅ Ready to Build
