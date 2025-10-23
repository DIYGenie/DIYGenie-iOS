import SwiftUI
import RoomPlan
import UIKit

@MainActor
final class ARScanCoordinator: NSObject, RoomCaptureSessionDelegate, RoomCaptureViewDelegate, NSSecureCoding {
    
    private let dismissAction: () -> Void
    weak var progressView: UIProgressView?

    // MARK: NSSecureCoding
    static var supportsSecureCoding: Bool { true }

    // Coordinator is not expected to be archived; provide a minimal implementation.
    func encode(with coder: NSCoder) {
        // No-op: this object is not intended for archival.
    }

    required init?(coder: NSCoder) {
        // Provide a default dismiss action that simply does nothing when decoded.
        // This path should never be hit in normal operation.
        self.dismissAction = { }
        super.init()
    }

    // Provide a convenience init to satisfy potential ObjC initializers.
    override init() {
        self.dismissAction = { }
        super.init()
    }

    init(dismiss: DismissAction) {
        self.dismissAction = { dismiss() }
    }

    // MARK: RoomCaptureSessionDelegate
    func captureSession(_ session: RoomCaptureSession, didUpdate room: CapturedRoom) {
        // Update progress based on the number of detected walls. Adjust the divisor
        // according to your progress granularity.
        let totalWalls = max(1, room.walls.count)
        let progress = min(Float(totalWalls) / 10.0, 1.0)
        Task { @MainActor in
            self.progressView?.setProgress(progress, animated: true)
        }
        print("📏 Scanning… \(room.walls.count) walls detected.")
    }

    func captureSession(_ session: RoomCaptureSession, didEndWith data: CapturedRoomData, error: Error?) {
        // When the session stops, the delegate will also receive the processed
        // CapturedRoom via captureView(didPresent:). You can process the raw
        // CapturedRoomData here if needed.
        if let error {
            print("❌ Scan ended with error: \(error.localizedDescription)")
        }
    }

    // MARK: RoomCaptureViewDelegate
    func captureView(shouldPresent roomDataForProcessing: CapturedRoomData, error: Error?) -> Bool {
        // Return true to allow RoomPlan to post‑process the captured data and
        // deliver a CapturedRoom in captureView(didPresent:).
        return true
    }

    func captureView(didPresent processedResult: CapturedRoom, error: Error?) {
        if let error {
            print("❌ Error processing result: \(error.localizedDescription)")
            return
        }
        print("✅ Post‑processed room available. Exporting to USDZ…")
        Task { @MainActor in
            let filename = "scan_\(UUID().uuidString.prefix(8)).usdz"
            let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
            do {
                try processedResult.export(to: url)
                print("💾 Exported scan to: \(url.path)")
                self.presentShareSheet(for: url)
                self.dismissAction()
            } catch {
                print("❌ Export failed: \(error.localizedDescription)")
            }
        }
    }

    // Presents a share sheet with the exported USDZ file.
    private func presentShareSheet(for url: URL) {
        let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        // Find the root view controller and present the share sheet.
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let root = scene.windows.first?.rootViewController {
            root.present(activityVC, animated: true)
        }
    }
}

/// A SwiftUI wrapper around RoomPlan’s `RoomCaptureView`.
///
/// This implementation avoids using the non‑public `RoomCaptureViewController` type and
/// instead embeds the framework’s provided `RoomCaptureView` inside a SwiftUI view.
/// It displays a progress bar and a finish button, exports the final room model
/// to a USDZ file, and presents a share sheet when the scan completes.  The
/// coordinator conforms to both `RoomCaptureSessionDelegate` and
/// `RoomCaptureViewDelegate` to receive live updates and post‑processed results.
@available(iOS 16.0, *)
struct ARScanView: UIViewRepresentable {
    @Environment(\.dismiss) private var dismiss

    func makeUIView(context: Context) -> RoomCaptureView {
        // Create the capture view provided by RoomPlan.
        let captureView = RoomCaptureView(frame: .zero)

        // Configure and start the capture session.
        let configuration = RoomCaptureSession.Configuration()
        captureView.captureSession.delegate = context.coordinator
        captureView.delegate = context.coordinator
        captureView.captureSession.run(configuration: configuration)

        // Add a progress bar to visualize scanning progress.
        let progressView = UIProgressView(progressViewStyle: .bar)
        progressView.trackTintColor = UIColor.systemGray5
        progressView.progressTintColor = UIColor.systemPurple
        progressView.translatesAutoresizingMaskIntoConstraints = false
        captureView.addSubview(progressView)
        NSLayoutConstraint.activate([
            progressView.topAnchor.constraint(equalTo: captureView.safeAreaLayoutGuide.topAnchor, constant: 10),
            progressView.leadingAnchor.constraint(equalTo: captureView.leadingAnchor, constant: 16),
            progressView.trailingAnchor.constraint(equalTo: captureView.trailingAnchor, constant: -16),
            progressView.heightAnchor.constraint(equalToConstant: 6)
        ])
        context.coordinator.progressView = progressView

        // Add a finish button to stop scanning early.
        let finishButton = UIButton(type: .system)
        finishButton.setTitle("Finish Scan", for: .normal)
        finishButton.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        finishButton.backgroundColor = UIColor.systemPurple.withAlphaComponent(0.9)
        finishButton.setTitleColor(.white, for: .normal)
        finishButton.layer.cornerRadius = 12
        finishButton.translatesAutoresizingMaskIntoConstraints = false
        finishButton.addAction(UIAction { [weak captureView] _ in
            // Stop the scan when the user taps the button.
            captureView?.captureSession.stop()
        }, for: .touchUpInside)
        captureView.addSubview(finishButton)
        NSLayoutConstraint.activate([
            finishButton.bottomAnchor.constraint(equalTo: captureView.safeAreaLayoutGuide.bottomAnchor, constant: -30),
            finishButton.centerXAnchor.constraint(equalTo: captureView.centerXAnchor),
            finishButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 160),
            finishButton.heightAnchor.constraint(equalToConstant: 44)
        ])

        return captureView
    }

    func updateUIView(_ uiView: RoomCaptureView, context: Context) {
        // No dynamic updates are needed during the scan.
    }

    func makeCoordinator() -> ARScanCoordinator {
        ARScanCoordinator(dismiss: dismiss)
    }
}

