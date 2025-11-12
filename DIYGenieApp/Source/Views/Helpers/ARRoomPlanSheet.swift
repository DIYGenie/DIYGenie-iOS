//
//  ARRoomPlanSheet.swift
//  DIYGenieApp
//
//  SwiftUI wrapper around RoomPlan using a UIViewController so the
//  RoomCaptureView always fills the screen and the session is started/stopped
//  at correct lifecycle points (prevents black preview on some devices).
//

import SwiftUI
import UIKit
#if canImport(RoomPlan)
import RoomPlan
#endif

#if canImport(RoomPlan)
@available(iOS 17.0, *)
struct ARRoomPlanSheet: UIViewControllerRepresentable {
    let projectId: String
    let onExport: (URL) -> Void   // returns temp .usdz URL once

    func makeCoordinator() -> Coordinator { Coordinator(onExport: onExport) }

    func makeUIViewController(context: Context) -> ARRoomPlanViewController {
        let vc = ARRoomPlanViewController()
        vc.coordinator = context.coordinator
        return vc
    }

    func updateUIViewController(_ uiViewController: ARRoomPlanViewController, context: Context) {
        // no-op
    }

    // MARK: - Nested VC
    final class ARRoomPlanViewController: UIViewController, RoomCaptureSessionDelegate, RoomCaptureViewDelegate {
        var coordinator: Coordinator!
        let captureView = RoomCaptureView()
        private var hasExported = false
        private var shouldExport = true
        private var isRunning = false

        private let closeButton = UIButton(type: .system)
        private let finishButton = UIButton(type: .system)

        override func viewDidLoad() {
            super.viewDidLoad()
            view.backgroundColor = .black

            captureView.frame = view.bounds
            captureView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            view.addSubview(captureView)

            captureView.captureSession.delegate = self
            captureView.delegate = self

            // UI overlay buttons
            setupOverlayUI()
        }

        private func setupOverlayUI() {
            // Close button (top-left)
            closeButton.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
            closeButton.tintColor = .white
            closeButton.backgroundColor = UIColor.black.withAlphaComponent(0.4)
            closeButton.layer.cornerRadius = 20
            closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
            closeButton.translatesAutoresizingMaskIntoConstraints = false

            // Finish button (bottom-center)
            if #available(iOS 15.0, *) {
                var cfg = UIButton.Configuration.filled()
                cfg.title = "Finish Scan"
                cfg.baseBackgroundColor = UIColor.systemBlue.withAlphaComponent(0.9)
                cfg.baseForegroundColor = .white
                cfg.contentInsets = NSDirectionalEdgeInsets(top: 12, leading: 18, bottom: 12, trailing: 18)
                finishButton.configuration = cfg
                finishButton.titleLabel?.font = .boldSystemFont(ofSize: 17)
            } else {
                finishButton.setTitle("Finish Scan", for: .normal)
                finishButton.setTitleColor(.white, for: .normal)
                finishButton.titleLabel?.font = .boldSystemFont(ofSize: 17)
                finishButton.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.9)
                finishButton.layer.cornerRadius = 12
                finishButton.contentEdgeInsets = UIEdgeInsets(top: 12, left: 18, bottom: 12, right: 18)
            }
            finishButton.addTarget(self, action: #selector(finishTapped), for: .touchUpInside)
            finishButton.translatesAutoresizingMaskIntoConstraints = false
        }

        private func startSessionIfNeeded() {
            guard !isRunning else { return }
            let config = RoomCaptureSession.Configuration()
            captureView.captureSession.run(configuration: config)
            isRunning = true
            print("[ARRoomPlan] Session started")
        }

        override func viewDidAppear(_ animated: Bool) {
            super.viewDidAppear(animated)
            // Start after presentation to avoid zero-sized layer issues
            startSessionIfNeeded()
        }

        override func viewWillDisappear(_ animated: Bool) {
            super.viewWillDisappear(animated)
            if isRunning {
                captureView.captureSession.stop()
                isRunning = false
                print("[ARRoomPlan] Session stopped")
            }
        }

        // Live updates if desired
        func captureSession(_ session: RoomCaptureSession, didUpdate room: CapturedRoom) { }

        // Finished capture → export .usdz → return URL
        func captureSession(_ session: RoomCaptureSession, didEndWith room: CapturedRoom, error: Error?) {
            guard !hasExported else { return }
            if let error = error { print("RoomPlan error:", error.localizedDescription); return }
            hasExported = true
            guard shouldExport else { return }
            let tmp = FileManager.default.temporaryDirectory
                .appendingPathComponent("scan-\(UUID().uuidString).usdz")
            do {
                try room.export(to: tmp)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.10) { [weak self] in
                    // Hand result back to SwiftUI after a brief delay; SwiftUI will close the sheet.
                    print("[ARRoomPlan] Exported USDZ to: \(tmp.path)")
                    self?.coordinator.onExport(tmp)
                }
            } catch {
                print("Export failed:", error.localizedDescription)
            }
        }

        @objc private func closeTapped() {
            shouldExport = false
            if isRunning {
                captureView.captureSession.stop()
                isRunning = false
                print("[ARRoomPlan] Session stopped")
            }
            dismiss(animated: true)
        }

        @objc private func finishTapped() {
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
            shouldExport = true
            if isRunning {
                captureView.captureSession.stop() // triggers didEndWith
                isRunning = false
                print("[ARRoomPlan] Session stopped")
            }
        }
    }

    // MARK: - Coordinator
    final class Coordinator: NSObject {
        let onExport: (URL) -> Void
        init(onExport: @escaping (URL) -> Void) { self.onExport = onExport }
    }
}
#endif
 
