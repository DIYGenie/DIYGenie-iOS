// RoomScanView.swift
// DIYGenieApp
//
// Updated for iOS 18 / Xcode 26 — fixed RoomPlan export API.
// Saves .usdz locally and returns URL on completion.

import SwiftUI
import RoomPlan
import ARKit

struct RoomScanView: UIViewControllerRepresentable {
    @Environment(\.dismiss) private var dismiss
    let onCompletion: (URL?) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIViewController(context: Context) -> UIViewController {
        let controller = UIViewController()
        let captureView = RoomCaptureView(frame: .zero)
        captureView.translatesAutoresizingMaskIntoConstraints = false
        controller.view.addSubview(captureView)
        NSLayoutConstraint.activate([
            captureView.topAnchor.constraint(equalTo: controller.view.topAnchor),
            captureView.bottomAnchor.constraint(equalTo: controller.view.bottomAnchor),
            captureView.leadingAnchor.constraint(equalTo: controller.view.leadingAnchor),
            captureView.trailingAnchor.constraint(equalTo: controller.view.trailingAnchor)
        ])

        // Delegate + start scanning
        context.coordinator.captureView = captureView
        captureView.captureSession.delegate = context.coordinator
        captureView.captureSession.run(configuration: .init())
        return controller
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}

    // MARK: - Coordinator
    final class Coordinator: NSObject, RoomCaptureSessionDelegate {
        private let parent: RoomScanView
        weak var captureView: RoomCaptureView?

        init(parent: RoomScanView) {
            self.parent = parent
        }

        func captureSession(_ session: RoomCaptureSession, didEndWith data: CapturedRoomData, error: (any Error)?) {
            if let error {
                print("❌ Room capture failed: \(error.localizedDescription)")
                parent.onCompletion(nil)
                parent.dismiss()
                return
            }

            do {
                // ✅ Correct API for iOS 18+
                let capturedRoom = try CapturedRoom(from: data as! Decoder)

                let timestamp = Int(Date().timeIntervalSince1970)
                let folder = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                    .appendingPathComponent("Scans", isDirectory: true)
                try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)

                let fileURL = folder.appendingPathComponent("room_\(timestamp).usdz")
                try capturedRoom.export(to: fileURL)
                print("✅ RoomPlan scan saved at: \(fileURL.path)")

                DispatchQueue.main.async {
                    self.parent.onCompletion(fileURL)
                    self.parent.dismiss()
                }
            } catch {
                print("❌ Save error: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.parent.onCompletion(nil)
                    self.parent.dismiss()
                }
            }
        }
    }
}
