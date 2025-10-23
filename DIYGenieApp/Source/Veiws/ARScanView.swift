import SwiftUI
import RoomPlan
import UIKit

/// A SwiftUI wrapper around RoomPlan’s scanning API using RoomCaptureView.
///
/// This view embeds a `RoomCaptureView` and displays a progress bar and a finish
/// button. When scanning completes, it writes a placeholder USDZ file to disk and
/// presents a share sheet (you can replace the placeholder with real RoomPlan export
/// once you hook up the model export API in your project).
@available(iOS 16.0, *)
struct ARScanView: UIViewRepresentable {
    @Environment(\.dismiss) private var dismiss

    // Coordinator owns the session and acts as delegate.
    final class Coordinator: NSObject, RoomCaptureSessionDelegate {
        let dismiss: DismissAction
        let session = RoomCaptureSession()
        weak var progressView: UIProgressView?

        init(dismiss: DismissAction) {
            self.dismiss = dismiss
            super.init()
            session.delegate = self
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

        /// Called when scanning completes. For now, writes a small placeholder USDZ-like file
        /// and presents a share sheet so the flow compiles and is testable end-to-end.
        func captureSession(_ session: RoomCaptureSession, didEndWith data: CapturedRoomData, error: Error?) {
            print("✅ Scan finished — preparing export…")
            Task { @MainActor in
                do {
                    // NOTE: Replace this with RoomPlan's model export when you wire it up.
                    let filename = "scan_\(UUID().uuidString.prefix(8)).usdz"
                    let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
                    let placeholder = Data("Placeholder USDZ — replace with real export".utf8)
                    try placeholder.write(to: url, options: .atomic)
                    print("💾 Wrote placeholder to: \(url.path)")
                    presentShareSheet(for: url)
                } catch {
                    print("❌ Export failed: \(error.localizedDescription)")
                }
                // Dismiss the SwiftUI view after processing completes.
                dismiss()
            }
        }

        // MARK: Helper
        /// Presents a share sheet for the exported USDZ file.
        @MainActor
        private func presentShareSheet(for url: URL) {
            let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)
            if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let root = scene.windows.first?.rootViewController {
                root.present(activityVC, animated: true)
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(dismiss: dismiss)
    }

    func makeUIView(context: Context) -> RoomCaptureView {
        let captureView = RoomCaptureView(frame: .zero)
        captureView.captureSession = context.coordinator.session

        // Configure and start the capture session.
        let configuration = RoomCaptureSession.Configuration()
        context.coordinator.session.run(configuration: configuration)

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

        // Add a finish button to let the user stop scanning early.
        let finishButton = UIButton(type: .system)
        finishButton.setTitle("Finish Scan", for: .normal)
        finishButton.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        finishButton.backgroundColor = UIColor.systemPurple.withAlphaComponent(0.9)
        finishButton.setTitleColor(.white, for: .normal)
        finishButton.layer.cornerRadius = 12
        finishButton.translatesAutoresizingMaskIntoConstraints = false
        finishButton.addAction(UIAction { [weak session = context.coordinator.session] _ in
            session?.stop()
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

    func updateUIView(_ uiView: RoomCaptureView, context: Context) { }
}
