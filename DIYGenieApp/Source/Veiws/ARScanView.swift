import SwiftUI
import RoomPlan

struct ARScanView: UIViewControllerRepresentable {

    // MARK: - Make UIViewController
    func makeUIViewController(context: Context) -> UIViewController {
        let viewController = UIViewController()

        // Create RoomCaptureView
        let captureView = RoomCaptureView(frame: .zero)
        captureView.delegate = context.coordinator

        // Start a capture session
        let configuration = RoomCaptureSession.Configuration()
        captureView.captureSession.run(configuration: configuration)

        // Add to controller
        viewController.view = captureView
        return viewController
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) { }

    func makeCoordinator() -> Coordinator {
        Coordinator(coder: <#NSCoder#>) ?? <#default value#>
    }

    // MARK: - Coordinator
    @objc(_TtCV11DIYGenieApp10ARScanView11Coordinator)class Coordinator: NSObject, RoomCaptureViewDelegate, RoomCaptureSessionDelegate {
        func encode(with coder: NSCoder) {
            <#code#>
        }
        
        required init?(coder: NSCoder) {
            <#code#>
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
