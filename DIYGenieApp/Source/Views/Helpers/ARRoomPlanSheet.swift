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
    
    // MARK: - Coordinator
    final class Coordinator {
        let onExport: (URL) -> Void

        init(onExport: @escaping (URL) -> Void) {
            self.onExport = onExport
        }
    }

    // MARK: - Nested VC
    final class ARRoomPlanViewController: UIViewController, RoomCaptureViewDelegate, RoomCaptureSessionDelegate {
        var coordinator: Coordinator!
        
        let captureView = RoomCaptureView()
        private var hasExported = false
        private var exportedURL: URL?
        
        private let closeButton = UIButton(type: .system)
        private let finishButton = UIButton(type: .system)
        private let confirmButton = UIButton(type: .system)
        
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
            confirmButton.alpha = 0
            confirmButton.isEnabled = false
            confirmButton.addTarget(self, action: #selector(confirmTapped), for: .touchUpInside)
            
            view.addSubview(closeButton)
            view.addSubview(finishButton)
            view.addSubview(confirmButton)
            
            NSLayoutConstraint.activate([
                closeButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 12),
                closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
                closeButton.widthAnchor.constraint(equalToConstant: 40),
                closeButton.heightAnchor.constraint(equalToConstant: 40),
                
                finishButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                finishButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
                
                confirmButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                confirmButton.bottomAnchor.constraint(equalTo: finishButton.topAnchor, constant: -12)
            ])
        }
        
        // MARK: - Buttons
        @objc private func closeTapped() {
            captureView.captureSession.stop()
            dismiss(animated: true)
        }
        
        @objc private func finishTapped() {
            if exportedURL != nil {
                exportedURL = nil
                hasExported = false
                UIView.animate(withDuration: 0.2) {
                    self.confirmButton.alpha = 0
                }
                confirmButton.isEnabled = false
                finishButton.setTitle("Finish Scan", for: .normal)
                let config = RoomCaptureSession.Configuration()
                captureView.captureSession.run(configuration: config)
            } else {
                finishButton.isEnabled = false
                captureView.captureSession.stop()
            }
        }
        
        @objc private func confirmTapped() {
            guard let url = exportedURL else { return }
            confirmButton.isEnabled = false
            coordinator.onExport(url)
            dismiss(animated: true)
        }
        
        // MARK: - RoomCaptureSessionDelegate
        func captureSession(_ session: RoomCaptureSession, didEndWith room: CapturedRoom, error: Error?) {
            guard !hasExported else { return }
            hasExported = true
            
            if let error = error {
                print("RoomPlan error: \(error.localizedDescription)")
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    self.hasExported = false
                    self.exportedURL = nil
                    self.finishButton.isEnabled = true
                    self.confirmButton.isEnabled = false
                    UIView.animate(withDuration: 0.2) {
                        self.confirmButton.alpha = 0
                    }
                    self.dismiss(animated: true)
                }
                return
            }
            
            let tmpURL = FileManager.default.temporaryDirectory
                .appendingPathComponent("scan-\(UUID().uuidString).usdz")
            
            do {
                try room.export(to: tmpURL)
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    self.exportedURL = tmpURL
                    self.finishButton.setTitle("Rescan", for: .normal)
                    self.finishButton.isEnabled = true
                    self.confirmButton.isEnabled = true
                    UIView.animate(withDuration: 0.25) {
                        self.confirmButton.alpha = 1
                    }
                }
            } catch {
                print("Export failed: \(error.localizedDescription)")
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    self.hasExported = false
                    self.exportedURL = nil
                    self.finishButton.isEnabled = true
                    self.confirmButton.isEnabled = false
                    UIView.animate(withDuration: 0.2) {
                        self.confirmButton.alpha = 0
                    }
                    self.dismiss(animated: true)
                }
            }
        }
        
    }
}
#endif
