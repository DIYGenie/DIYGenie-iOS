import SwiftUI
import ARKit
import RoomPlan

// RoomPlan is available starting iOS 16. We'll add iOS 16 minimum and
// handle iOS 17+ async export when available.
@available(iOS 16.0, *)
struct ARScanView: UIViewControllerRepresentable {
    typealias UIViewControllerType = RoomCaptureViewController

    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> RoomCaptureViewController {
        let controller = RoomCaptureViewController()
        controller.captureSession.delegate = context.coordinator
        controller.delegate = context.coordinator

        // Configure and start the capture session
        let configuration = RoomCaptureSession.Configuration()
        controller.captureSession.run(configuration: configuration)

        // Add a Finish button overlay
        let finishButton = UIButton(type: .system)
        finishButton.setTitle("Finish Scan", for: .normal)
        finishButton.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        finishButton.backgroundColor = UIColor.systemPurple.withAlphaComponent(0.9)
        finishButton.setTitleColor(.white, for: .normal)
        finishButton.layer.cornerRadius = 12
        finishButton.contentEdgeInsets = UIEdgeInsets(top: 10, left: 16, bottom: 10, right: 16)
        finishButton.translatesAutoresizingMaskIntoConstraints = false
        finishButton.addAction(UIAction { [weak controller] _ in
            controller?.captureSession.stop()
            self.dismiss()
        }, for: .touchUpInside)

        controller.view.addSubview(finishButton)
        NSLayoutConstraint.activate([
            finishButton.bottomAnchor.constraint(equalTo: controller.view.safeAreaLayoutGuide.bottomAnchor, constant: -30),
            finishButton.centerXAnchor.constraint(equalTo: controller.view.centerXAnchor),
            finishButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 160),
            finishButton.heightAnchor.constraint(equalToConstant: 48)
        ])

        return controller
    }

    func updateUIViewController(_ uiViewController: RoomCaptureViewController, context: Context) {
        // No dynamic updates needed during scanning for now.
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(onFinish: { self.dismiss() })
    }

    // MARK: - Coordinator
    class Coordinator: NSObject, RoomCaptureSessionDelegate, RoomCaptureViewDelegate {
        private let onFinish: () -> Void

        init(onFinish: @escaping () -> Void) {
            self.onFinish = onFinish
        }

        // RoomCaptureViewDelegate (optional callbacks can be added here if needed)
        func captureView(_ view: RoomCaptureView, didPresent message: String) {
            // Example hook for UI messages from RoomPlan, if any.
        }

        // MARK: RoomCaptureSessionDelegate
        func captureSession(_ session: RoomCaptureSession, didUpdate room: CapturedRoom) {
            // Progress updates while scanning
            print("📏 Scanning... \(room.walls.count) walls detected.")
        }

        func captureSession(_ session: RoomCaptureSession, didEndWith data: CapturedRoomData) {
            print("✅ Scan finished — exporting…")

            let filename = "scan_\(UUID().uuidString.prefix(8)).usdz"
            let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)

            // Handle export across SDK versions: iOS 17 introduced async export options.
            if #available(iOS 17.0, *) {
                Task {
                    do {
                        try await data.export(to: url)
                        print("💾 Exported scan to \(url.path)")
                    } catch {
                        print("❌ Async export failed: \(error.localizedDescription)")
                    }
                    // Dismiss after attempting export
                    self.onFinish()
                }
            } else {
                do {
                    try data.export(to: url)
                    print("💾 Exported scan to \(url.path)")
                } catch {
                    print("❌ Export failed: \(error.localizedDescription)")
                }
                // Dismiss after attempting export
                self.onFinish()
            }
        }
    }
}
