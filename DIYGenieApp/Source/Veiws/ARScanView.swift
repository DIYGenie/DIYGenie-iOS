import SwiftUI
import ARKit
import RoomPlan

@available(iOS 16.0, *)
struct ARScanView: UIViewControllerRepresentable {
    typealias UIViewControllerType = RoomCaptureViewController
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> RoomCaptureViewController {
        let controller = RoomCaptureViewController()
        controller.captureSession.delegate = context.coordinator
        controller.delegate = context.coordinator

        let configuration = RoomCaptureSession.Configuration()
        controller.captureSession.run(configuration: configuration)

        // Progress Bar
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

        // Finish Button
        let finishButton = UIButton(type: .system)
        finishButton.setTitle("Finish Scan", for: .normal)
        finishButton.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        finishButton.backgroundColor = UIColor.systemPurple.withAlphaComponent(0.9)
        finishButton.setTitleColor(.white, for: .normal)
        finishButton.layer.cornerRadius = 12
        finishButton.translatesAutoresizingMaskIntoConstraints = false
        finishButton.addAction(UIAction { [weak controller] _ in
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

    func updateUIViewController(_ uiViewController: RoomCaptureViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(dismiss: dismiss)
    }

    @objc(_TtCV11DIYGenieApp10ARScanView11Coordinator)final class Coordinator: NSObject, RoomCaptureViewDelegate, RoomCaptureSessionDelegate {
        private let dismiss: DismissAction
        weak var progressView: UIProgressView?

        init(dismiss: DismissAction) {
            self.dismiss = dismiss
        }

        // Called continuously while scanning
        func captureSession(_ session: RoomCaptureSession, didUpdate room: CapturedRoom) {
            let totalWalls = max(1, room.walls.count)
            let progress = min(Float(totalWalls) / 10.0, 1.0) // assumes ~10 walls = full room
            DispatchQueue.main.async {
                self.progressView?.setProgress(progress, animated: true)
            }
            print("📏 Scanning… \(room.walls.count) walls detected.")
        }

        // Called when scan completes
        func captureSession(_ session: RoomCaptureSession, didEndWith data: CapturedRoomData) {
            print("✅ Scan finished — exporting to USDZ…")
            Task {
                let filename = "scan_\(UUID().uuidString.prefix(8)).usdz"
                let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
                do {
                    try await data.export(to: url)
                    print("💾 Exported scan to: \(url.path)")
                    await MainActor.run { self.presentShareSheet(for: url) }
                } catch {
                    print("❌ Export failed: \(error.localizedDescription)")
                }
            }
        }

        @MainActor
        private func presentShareSheet(for url: URL) {
            let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)
            if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let root = scene.windows.first?.rootViewController {
                root.present(activityVC, animated: true)
            }
        }
    }
}
