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
import QuickLook
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
    
    // MARK: - Coordinator
    final class Coordinator {
        let onExport: (URL) -> Void

        init(onExport: @escaping (URL) -> Void) {
            self.onExport = onExport
        }
    }

    // MARK: - Nested VC
    final class ARRoomPlanViewController: UIViewController, RoomCaptureViewDelegate, RoomCaptureSessionDelegate, QLPreviewControllerDataSource, QLPreviewControllerDelegate {
        var coordinator: Coordinator!

        let captureView = RoomCaptureView()
        private var hasExported = false
        private var exportedURL: URL?
        private var previewItem: PreviewItem?

        private let closeButton = UIButton(type: .system)
        private let finishButton = UIButton(type: .system)
        private let confirmButton = UIButton(type: .system)
        private let finishedStack = UIStackView()
        private let finishedTitleLabel = UILabel()
        private let finishedSubtitleLabel = UILabel()
        private let viewScanButton = UIButton(type: .system)
        
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
            closeButton.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
            closeButton.tintColor = .white
            closeButton.backgroundColor = UIColor.black.withAlphaComponent(0.4)
            closeButton.layer.cornerRadius = 20
            closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
            closeButton.translatesAutoresizingMaskIntoConstraints = false
            
            finishButton.setTitle("Finish Scan", for: .normal)
            finishButton.setTitleColor(.white, for: .normal)
            finishButton.titleLabel?.font = .boldSystemFont(ofSize: 17)
            finishButton.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.9)
            finishButton.layer.cornerRadius = 12
            finishButton.contentEdgeInsets = UIEdgeInsets(top: 12, left: 18, bottom: 12, right: 18)
            finishButton.addTarget(self, action: #selector(finishTapped), for: .touchUpInside)
            finishButton.translatesAutoresizingMaskIntoConstraints = false
            
            confirmButton.setTitle("Confirm", for: .normal)
            confirmButton.setTitleColor(.white, for: .normal)
            confirmButton.titleLabel?.font = .boldSystemFont(ofSize: 17)
            confirmButton.backgroundColor = UIColor.systemGreen.withAlphaComponent(0.92)
            confirmButton.layer.cornerRadius = 12
            confirmButton.contentEdgeInsets = UIEdgeInsets(top: 12, left: 24, bottom: 12, right: 24)
            confirmButton.translatesAutoresizingMaskIntoConstraints = false
            confirmButton.alpha = 1
            confirmButton.isEnabled = true
            confirmButton.addTarget(self, action: #selector(confirmTapped), for: .touchUpInside)

            finishedStack.axis = .vertical
            finishedStack.alignment = .center
            finishedStack.spacing = 8
            finishedStack.translatesAutoresizingMaskIntoConstraints = false
            finishedStack.alpha = 0

            finishedTitleLabel.text = "Finished scan ready"
            finishedTitleLabel.font = .boldSystemFont(ofSize: 18)
            finishedTitleLabel.textColor = .white

            finishedSubtitleLabel.text = "Preview and confirm to attach it to your project."
            finishedSubtitleLabel.font = .systemFont(ofSize: 14, weight: .medium)
            finishedSubtitleLabel.textColor = UIColor.white.withAlphaComponent(0.85)
            finishedSubtitleLabel.numberOfLines = 2
            finishedSubtitleLabel.textAlignment = .center

            viewScanButton.setTitle("View Finished Scan", for: .normal)
            viewScanButton.setTitleColor(.white, for: .normal)
            viewScanButton.titleLabel?.font = .boldSystemFont(ofSize: 16)
            viewScanButton.backgroundColor = UIColor.white.withAlphaComponent(0.18)
            viewScanButton.layer.cornerRadius = 10
            viewScanButton.contentEdgeInsets = UIEdgeInsets(top: 10, left: 18, bottom: 10, right: 18)
            viewScanButton.isEnabled = false
            viewScanButton.alpha = 0.7
            viewScanButton.addTarget(self, action: #selector(viewScanTapped), for: .touchUpInside)

            finishedStack.addArrangedSubview(finishedTitleLabel)
            finishedStack.addArrangedSubview(finishedSubtitleLabel)
            finishedStack.addArrangedSubview(viewScanButton)

            view.addSubview(closeButton)
            view.addSubview(finishButton)
            view.addSubview(confirmButton)
            view.addSubview(finishedStack)

            NSLayoutConstraint.activate([
                closeButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 12),
                closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
                closeButton.widthAnchor.constraint(equalToConstant: 40),
                closeButton.heightAnchor.constraint(equalToConstant: 40),

                finishButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                finishButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),

                confirmButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                confirmButton.bottomAnchor.constraint(equalTo: finishButton.topAnchor, constant: -12),

                finishedStack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                finishedStack.bottomAnchor.constraint(equalTo: confirmButton.topAnchor, constant: -16),
                finishedStack.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 24),
                finishedStack.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -24)
            ])
        }
        
        // MARK: - Buttons
        @objc private func closeTapped() {
            captureView.captureSession.stop()
            dismiss(animated: true)
        }
        
        @objc private func finishTapped() {
            // Stop live scanning
            captureView.captureSession.stop()

            // If we already exported, reset and allow rescan
            if exportedURL != nil {
                exportedURL = nil
                hasExported = false
                previewItem = nil

                UIView.animate(withDuration: 0.2) {
                    self.confirmButton.alpha = 0
                    self.finishedStack.alpha = 0
                }

                confirmButton.isEnabled = false
                viewScanButton.isEnabled = false
                viewScanButton.alpha = 0.7
                finishButton.setTitle("Finish Scan", for: .normal)

                let config = RoomCaptureSession.Configuration()
                captureView.captureSession.run(configuration: config)
                return
            }

            // First export – let the session delegate handle export when it ends
            finishButton.isEnabled = false
            captureView.captureSession.stop()
        }
        
        @objc private func confirmTapped() {
            // If we have an exported scan, attach it and return to New Project
            if let url = exportedURL {
                confirmButton.isEnabled = false
                coordinator.onExport(url)
                return
            }

            // If no export exists yet, guide the user instead of doing nothing
            let alert = UIAlertController(
                title: "Scan Not Ready",
                message: "Tap \"Finish Scan\" first to capture the room, then tap \"Confirm\" to attach it to your project.",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            present(alert, animated: true)
        }

        @objc private func viewScanTapped() {
            guard previewItem != nil else { return }
            let previewController = QLPreviewController()
            previewController.dataSource = self
            previewController.delegate = self
            present(previewController, animated: true)
        }
        
        // MARK: - RoomCaptureSessionDelegate
        func captureSession(_ session: RoomCaptureSession, didEndWith room: CapturedRoom, error: Error?) {
            guard !hasExported else { return }
            hasExported = true

            if let error = error {
                print("RoomPlan error:", error.localizedDescription)

                DispatchQueue.main.async {
                    self.hasExported = false
                    self.exportedURL = nil
                    self.finishButton.isEnabled = true
                    self.confirmButton.isEnabled = false
                    self.previewItem = nil
                    self.viewScanButton.isEnabled = false
                    self.viewScanButton.alpha = 0.7

                    UIView.animate(withDuration: 0.2) {
                        self.confirmButton.alpha = 0
                        self.finishedStack.alpha = 0
                    }
                }
                return
            }

            let tmpURL = FileManager.default.temporaryDirectory
                .appendingPathComponent("scan-\(UUID().uuidString).usdz")

            do {
                try room.export(to: tmpURL)
                DispatchQueue.main.async {
                    self.exportedURL = tmpURL
                    self.previewItem = PreviewItem(url: tmpURL)

                    self.finishButton.setTitle("Rescan", for: .normal)
                    self.finishButton.isEnabled = true
                    self.confirmButton.isEnabled = true
                    self.viewScanButton.isEnabled = true

                    UIView.animate(withDuration: 0.25) {
                        self.confirmButton.alpha = 1
                        self.finishedStack.alpha = 1
                        self.viewScanButton.alpha = 1
                    }
                }
            } catch {
                print("Export failed:", error.localizedDescription)

                DispatchQueue.main.async {
                    self.hasExported = false
                    self.exportedURL = nil
                    self.finishButton.isEnabled = true
                    self.confirmButton.isEnabled = false
                    self.previewItem = nil
                    self.viewScanButton.isEnabled = false
                    self.viewScanButton.alpha = 0.7

                    UIView.animate(withDuration: 0.2) {
                        self.confirmButton.alpha = 0
                        self.finishedStack.alpha = 0
                    }
                }
            }
        }

        // MARK: - QLPreviewControllerDataSource
        func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
            previewItem == nil ? 0 : 1
        }

        func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
            previewItem!
        }

        // MARK: - Preview helper
        private final class PreviewItem: NSObject, QLPreviewItem {
            let previewItemURL: URL?

            init(url: URL) {
                self.previewItemURL = url
                super.init()
            }
        }
    }
}
#endif
