//
//  ARRoomPlanSheet.swift
//  DIYGenieApp
//

//
//  ARRoomPlanSheet.swift
//  DIYGenieApp
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
    let onExport: (URL) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onExport: onExport)
    }

    func makeUIViewController(context: Context) -> ARRoomPlanViewController {
        let vc = ARRoomPlanViewController()
        vc.coordinator = context.coordinator
        return vc
    }

    func updateUIViewController(_ uiViewController: ARRoomPlanViewController, context: Context) {
        // No dynamic updates needed for now.
    }

    // MARK: - Nested VC
    final class ARRoomPlanViewController: UIViewController, RoomCaptureViewDelegate, RoomCaptureSessionDelegate {
        var coordinator: Coordinator!

        let captureView = RoomCaptureView()
        private var hasExported = false

        private let closeButton = UIButton(type: .system)
        private let finishButton = UIButton(type: .system)

        override func viewDidLoad() {
            super.viewDidLoad()

            view.backgroundColor = .black

            // Add capture view full-screen
            captureView.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(captureView)
            NSLayoutConstraint.activate([
                captureView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                captureView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                captureView.topAnchor.constraint(equalTo: view.topAnchor),
                captureView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
            ])

            captureView.delegate = self
            captureView.captureSession.delegate = self

            setupOverlayUI()
        }

        override func viewDidAppear(_ animated: Bool) {
            super.viewDidAppear(animated)
            // Start RoomPlan session
            let config = RoomCaptureSession.Configuration()
            captureView.captureSession.run(configuration: config)
        }

        override func viewWillDisappear(_ animated: Bool) {
            super.viewWillDisappear(animated)
            // Stop when leaving
            captureView.captureSession.stop()
        }

        // MARK: - Overlay UI
        private func setupOverlayUI() {
            // Close button (top-left)
            closeButton.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
            closeButton.tintColor = .white
            closeButton.backgroundColor = UIColor.black.withAlphaComponent(0.4)
            closeButton.layer.cornerRadius = 20
            closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
            closeButton.translatesAutoresizingMaskIntoConstraints = false

            // Finish button (bottom-center)
            finishButton.setTitle("Finish Scan", for: .normal)
            finishButton.setTitleColor(.white, for: .normal)
            finishButton.titleLabel?.font = .boldSystemFont(ofSize: 17)
            finishButton.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.9)
            finishButton.layer.cornerRadius = 12
            finishButton.contentEdgeInsets = UIEdgeInsets(top: 12, left: 18, bottom: 12, right: 18)
            finishButton.addTarget(self, action: #selector(finishTapped), for: .touchUpInside)
            finishButton.translatesAutoresizingMaskIntoConstraints = false

            view.addSubview(closeButton)
            view.addSubview(finishButton)

            NSLayoutConstraint.activate([
                closeButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 12),
                closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
                closeButton.widthAnchor.constraint(equalToConstant: 40),
                closeButton.heightAnchor.constraint(equalToConstant: 40),

                finishButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                finishButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16)
            ])
        }

        // MARK: - Buttons
        @objc private func closeTapped() {
            captureView.captureSession.stop()
            dismiss(animated: true)
        }

        @objc private func finishTapped() {
            // Stopping the session will trigger didEndWith
            captureView.captureSession.stop()
        }

        // MARK: - RoomCaptureSessionDelegate
        func captureSession(_ session: RoomCaptureSession, didEndWith room: CapturedRoom, error: Error?) {
            guard !hasExported else { return }
            hasExported = true

            if let error = error {
                print("RoomPlan error: \(error.localizedDescription)")
                DispatchQueue.main.async { [weak self] in
                    self?.dismiss(animated: true)
                }
                return
            }

            let tmpURL = FileManager.default.temporaryDirectory
                .appendingPathComponent("scan-\(UUID().uuidString).usdz")

            do {
                try room.export(to: tmpURL)
                DispatchQueue.main.async { [weak self] in
                    self?.coordinator.onExport(tmpURL)
                    self?.dismiss(animated: true)
                }
            } catch {
                print("Export failed: \(error.localizedDescription)")
                DispatchQueue.main.async { [weak self] in
                    self?.dismiss(animated: true)
                }
            }
        }
    }

    // MARK: - Coordinator
    final class Coordinator {
        let onExport: (URL) -> Void
        init(onExport: @escaping (URL) -> Void) {
            self.onExport = onExport
        }
    }
}
#endif
