import SwiftUI
import RoomPlan
import UIKit

/// A SwiftUI wrapper around RoomPlan’s scanning API.
///
/// This view embeds a `RoomCaptureViewController` and displays a progress bar and a finish
/// button. When scanning completes, the captured room data is exported to a USDZ file
/// and a share sheet is presented. By conforming only to `RoomCaptureSessionDelegate` and
/// `NSCoding`, the coordinator avoids unimplemented protocol requirements.  The
/// delegate methods of `RoomCaptureSessionDelegate` provide live updates during the
/// scan and a completion callback when the scan ends, which is where the export
/// happens【734729638595212†L153-L177】.
@available(iOS 16.0, *)
struct ARScanView: UIViewControllerRepresentable {
    /// The type of view controller that this view represents.
    typealias UIViewControllerType = RoomCaptureViewController

    /// Used to dismiss the SwiftUI view when scanning finishes.
    @Environment(\.dismiss) private var dismiss

    /// Creates and configures a `RoomCaptureViewController`.
    func makeUIViewController(context: Context) -> RoomCaptureViewController {
        let controller = RoomCaptureViewController()
        // Set the capture session delegate to our coordinator to receive callbacks.
        controller.captureSession.delegate = context.coordinator

        // Configure and start the capture session.
        let configuration = RoomCaptureSession.Configuration()
        controller.captureSession.run(configuration: configuration)

        // Add a progress bar to visualize scanning progress.
        let progressView = UIProgressView(progressViewStyle: .bar)
        progressView.trackTintColor = UIColor.systemGray5
        progressView.progressTintColor = UIColor.systemPurple
        progressView.translatesAutoresizingMaskIntoConstraints = false
        controller.view.addSubview(progressView)
        NSLayoutConstraint.activate([
            progressView.topAnchor.constraint(equalTo: controller.view.safeAreaLayoutGuide.topAnchor, constant: 10),
            progressView.leadingAnchor.constraint(equalTo: controller.view.leadingAnchor, constant: 16),
            progressView.trailingAnchor.constraint(equalTo: controller.view.trailingAnchor, constant: -16),
            progressView.heightAnchor.constraint(equalToConstant: 6)
        ])
        context.coordinator.progressView = progressView

        // Add a finish button to let the user stop scanning early.
        let finishButton = UIButton(type: .system)
        finishButton.setTitle("Finish Scan", for: .normal)
        finishButton.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        finishButton.backgroundColor = UIColor.systemPurple.withAlphaComponent(0.9)
        finishButton.setTitleColor(.white, for: .normal)
        finishButton.layer.cornerRadius = 12
        finishButton.translatesAutoresizingMaskIntoConstraints = false
        finishButton.addAction(UIAction { [weak controller] _ in
            // Stop the scan when the user taps the button.
            controller?.captureSession.stop()
        }, for: .touchUpInside)
        controller.view.addSubview(finishButton)
        NSLayoutConstraint.activate([
            finishButton.bottomAnchor.constraint(equalTo: controller.view.safeAreaLayoutGuide.bottomAnchor, constant: -30),
            finishButton.centerXAnchor.constraint(equalTo: controller.view.centerXAnchor),
            finishButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 160),
            finishButton.heightAnchor.constraint(equalToConstant: 44)
        ])

        return controller
    }

    /// Updates the view controller. No dynamic updates are needed while scanning.
    func updateUIViewController(_ uiViewController: RoomCaptureViewController, context: Context) { }

    /// Creates the coordinator that acts as the capture session’s delegate.
    func makeCoordinator() -> Coordinator {
        Coordinator(dismiss: dismiss)
    }

    /// Coordinates interactions between the capture session and SwiftUI.
    ///
    /// The coordinator conforms to `RoomCaptureSessionDelegate` to receive scan updates
    /// and completion callbacks. It also conforms to `NSCoding` with stub implementations
    /// because `RoomCaptureSessionDelegate` inherits from `NSObject` and `NSCoding`.  By
    /// avoiding conformance to `RoomCaptureViewDelegate`, we sidestep additional
    /// required methods that aren’t needed when using `RoomCaptureViewController`【734729638595212†L153-L177】.
    final class Coordinator: NSObject, RoomCaptureSessionDelegate, NSCoding {
        /// Used to dismiss the SwiftUI view when scanning completes.
        private let dismiss: DismissAction
        /// A weak reference to the progress bar so it can be updated from delegate callbacks.
        weak var progressView: UIProgressView?

        init(dismiss: DismissAction) {
            self.dismiss = dismiss
        }

        // MARK: NSCoding
        /// Encodes the coordinator. This is unused but required by `NSCoding`.
        func encode(with coder: NSCoder) {
            // No-op; this object isn’t meant to be archived.
        }
        /// Creates a new coordinator from an archive. Unused in this context.
        required init?(coder: NSCoder) {
            return nil
        }

        // MARK: RoomCaptureSessionDelegate
        /// Provides continuous updates about the scanned room. Updates the progress bar based
        /// on the number of walls detected.
        func captureSession(_ session: RoomCaptureSession, didUpdate room: CapturedRoom) {
            let totalWalls = max(1, room.walls.count)
            let progress = min(Float(totalWalls) / 10.0, 1.0)
            DispatchQueue.main.async { [weak self] in
                self?.progressView?.setProgress(progress, animated: true)
            }
            print("📏 Scanning… \(room.walls.count) walls detected.")
        }

        /// Called when scanning completes. Exports the captured room data to a USDZ file
        /// and presents a share sheet. Dismisses the view afterwards.
        func captureSession(_ session: RoomCaptureSession, didEndWith data: CapturedRoomData, error: Error?) {
            print("✅ Scan finished — exporting to USDZ…")
            Task {
                let filename = "scan_\(UUID().uuidString.prefix(8)).usdz"
                let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
                do {
                    try await data.export(to: url)
                    print("💾 Exported scan to: \(url.path)")
                    // Present the share sheet on the main actor.
                    await MainActor.run { self.presentShareSheet(for: url) }
                } catch {
                    print("❌ Export failed: \(error.localizedDescription)")
                }
                // Dismiss the SwiftUI view after processing completes.
                await MainActor.run { self.dismiss() }
            }
        }

        // MARK: Helper
        /// Presents a share sheet for the exported USDZ file.
        @MainActor
        private func presentShareSheet(for url: URL) {
            let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)
            // Find the root view controller and present the share sheet.
            if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let root = scene.windows.first?.rootViewController {
                root.present(activityVC, animated: true)
            }
        }
    }
}
