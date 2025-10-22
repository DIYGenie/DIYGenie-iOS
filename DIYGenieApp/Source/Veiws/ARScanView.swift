import SwiftUI
import ARKit
import RoomPlan

struct ARScanView: UIViewControllerRepresentable {

    func makeUIViewController(context: Context) -> UIViewController {
        // Check for RoomPlan support
        guard ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh) else {
            // Fallback: if device doesn't support full mesh reconstruction
            let arView = ARSCNView()
            arView.session.run(ARWorldTrackingConfiguration())
            let vc = UIViewController()
            vc.view = arView
            return vc
        }
        // ✅ Create and configure RoomPlan (iOS 18 API)
        let captureView = RoomCaptureView(frame: .zero)
        captureView.delegate = context.coordinator

        // Configure session via captureView's internal session
        let config = RoomCaptureSession.Configuration()
        captureView.captureSession.run(configuration: config)

        // Present the capture view
        let vc = UIViewController()
        vc.view = captureView
        return vc
    }
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        // You can update UI or handle orientation changes here if needed
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(coder: <#NSCoder#>) ?? <#default value#>
    }

    @objc(_TtCV11DIYGenieApp10ARScanView11Coordinator)class Coordinator: NSObject, RoomCaptureViewDelegate, RoomCaptureSessionDelegate {
        func encode(with coder: NSCoder) {
            <#code#>
        }
        
        required init?(coder: NSCoder) {
            <#code#>
        }
        
        func captureView(_ view: RoomCaptureView, didEndWith data: CapturedRoomData) {
            print("✅ RoomPlan finished scanning. Data: \(data)")
            // You can process data here
        }

        func captureSession(_ session: RoomCaptureSession, didUpdate room: CapturedRoom) {
            print("🔄 Scanning… walls: \(room.walls.count)")
        }
    }
}
func captureView(_ view: RoomCaptureView, didEndWith room: CapturedRoom) {
    print("✅ Scan finished, exporting to USDZ…")
    
    let fileName = "scan_\(UUID().uuidString.prefix(8)).usdz"
    let url = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
    
    // ✅ Final stable RoomPlan export (iOS 17 & 18)
    Task {
        do {
            try room.export(to: url)
            print("💾 Exported scan to \(url.path)")
        } catch {
            print("❌ Export failed: \(error.localizedDescription)")
        }
    }
}
