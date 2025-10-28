import SwiftUI
import RoomPlan
import UIKit

struct ARScanView: UIViewControllerRepresentable {
    var onFinish: (URL?) -> Void

    func makeUIViewController(context: Context) -> ARScanViewController {
        let controller = ARScanViewController()
        controller.onFinish = onFinish
        return controller
    }

    func updateUIViewController(_ uiViewController: ARScanViewController, context: Context) {}
}

final class ARScanViewController: UIViewController, RoomCaptureViewDelegate {
    var onFinish: ((URL?) -> Void)?
    private var captureView: RoomCaptureView!
    private var configuration = RoomCaptureSession.Configuration()
    private var isScanning = false

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        showInstructions()
    }

    private func showInstructions() {
        let alert = UIAlertController(
            title: "📐 Room Scan",
            message: "Move slowly around the room.\n• Capture corners and walls.\n• Tap Finish when done.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Start Scan", style: .default) { _ in
            self.startScan()
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in
            self.dismiss(animated: true) {
                self.onFinish?(nil)
            }
        })
        present(alert, animated: true)
    }

    // MARK: - Start Scan
    private func startScan() {
        captureView = RoomCaptureView(frame: view.bounds)
        captureView.delegate = self
        captureView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(captureView)

        NSLayoutConstraint.activate([
            captureView.topAnchor.constraint(equalTo: view.topAnchor),
            captureView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            captureView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            captureView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        let finishButton = makeButton(title: "Finish", color: .systemBlue, action: #selector(finishScan))
        let cancelButton = makeButton(title: "Cancel", color: .systemRed, action: #selector(cancelScan))
        view.addSubview(finishButton)
        view.addSubview(cancelButton)

        NSLayoutConstraint.activate([
            finishButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            finishButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -24),
            cancelButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            cancelButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -24)
        ])

        isScanning = true
        captureView.captureSession.run(configuration: configuration)
    }

    // MARK: - Finish Scan
    @objc private func finishScan() {
        guard isScanning else { return }
        isScanning = false
        captureView.captureSession.stop()
        // The delegate method will handle exporting when scanning ends
    }

    // MARK: - Cancel
    @objc private func cancelScan() {
        captureView.captureSession.stop()
        dismiss(animated: true) {
            self.onFinish?(nil)
        }
    }

    // MARK: - RoomCaptureViewDelegate
    func captureView(_ view: RoomCaptureView, didEndWith data: CapturedRoom, error: Error?) {
        if let error = error {
            showError(message: "Scan failed: \(error.localizedDescription)")
            return
        }

        let fileName = "roomscan_\(UUID().uuidString).usdz"
        let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)

        do {
            try data.export(to: fileURL)
            uploadScan(fileURL: fileURL)
        } catch {
            showError(message: "Export failed: \(error.localizedDescription)")
        }
    }

    // MARK: - Upload (stub)
    private func uploadScan(fileURL: URL) {
        let publicURL = "https://uploads.supabase.co/roomscans/\(fileURL.lastPathComponent)"
        showSuccessAlert(publicURL: publicURL)
    }

    // MARK: - Alerts
    private func showSuccessAlert(publicURL: String) {
        let alert = UIAlertController(
            title: "✅ Scan Saved",
            message: "Your room scan has been uploaded.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            self.dismiss(animated: true) {
                self.onFinish?(URL(string: publicURL))
            }
        })
        present(alert, animated: true)
    }

    private func showError(message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    // MARK: - UI Helper
    private func makeButton(title: String, color: UIColor, action: Selector) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.backgroundColor = color
        button.tintColor = .white
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        button.layer.cornerRadius = 8
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: action, for: .touchUpInside)
        return button
    }
}
