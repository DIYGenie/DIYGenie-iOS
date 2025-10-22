import SwiftUI
import RoomPlan

struct ARScanView: UIViewControllerRepresentable {

    func makeUIViewController(context: Context) -> UIViewController {
        // Create capture view and set delegates
        let captureView = RoomCaptureView(frame: .zero)
        captureView.delegate = context.coordinator
        captureView.captureSession.delegate = context.coordinator

        // Start the capture session
        let configuration = RoomCaptureSession.Configuration()
        captureView.captureSession.run(configuration: configuration)

        // Host in a view controller
        let viewController = UIViewController()
        viewController.view = captureView
        return viewController
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) { }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    // MARK: - Coordinator
    @objc(_TtCV11DIYGenieApp10ARScanView11Coordinator)class Coordinator: NSObject, RoomCaptureViewDelegate, RoomCaptureSessionDelegate {
        
        override init() {
            super.init()
        }
        
        func encode(with coder: NSCoder) {
            // No-op
        }
        
        required init?(coder: NSCoder) {
            super.init()
        }
        
        // Called continuously while scanning
        func captureSession(_ session: RoomCaptureSession, didUpdate room: CapturedRoom) {
            print("📏 Scanning... \(room.walls.count) walls detected.")
        }

        // Called when scanning ends (user taps Done)
        func captureView(_ view: RoomCaptureView, didEndWith room: CapturedRoom) {
            print("✅ Scan finished — exporting to USDZ")

            let fileName = "scan_\(UUID().uuidString.prefix(8)).usdz"
            let url = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)

            Task {
                do {
                    try room.export(to: url)
                    print("💾 Exported scan to \(url.path)")
                } catch {
                    print("❌ Export failed: \(error.localizedDescription)")
                }
            }
        }
    }
}
