import SwiftUI
import RoomPlan
import UIKit
import Supabase

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
    private var hasShownInstructions = false
    private let accent = UIColor(red: 164/255, green: 90/255, blue: 255/255, alpha: 1)
    private let client = SupabaseClient(
        supabaseURL: URL(string: "https://YOUR_SUPABASE_PROJECT_URL")!,
        supabaseKey: "YOUR_SUPABASE_ANON_KEY"
    )

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        view.backgroundColor = .systemBackground
        if !hasShownInstructions {
            hasShownInstructions = true
            showInstructions()
        }
    }

    private func showInstructions() {
        let alert = UIAlertController(
            title: "📐 Room Scan",
            message: "Move slowly around the room:\n• Capture corners and walls.\n• Tap Finish when done.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in
            self.dismiss(animated: true) {
                self.onFinish?(nil)
            }
        })
        alert.addAction(UIAlertAction(title: "Start Scan", style: .default) { _ in
            self.startScan()
        })
        present(alert, animated: true)
    }

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

        let finishButton = makeButton(title: "Finish", color: accent, action: #selector(finishScan))
        let cancelButton = makeButton(title: "Cancel", color: .systemGray, action: #selector(cancelScan))
        view.addSubview(finishButton)
        view.addSubview(cancelButton)

        NSLayoutConstraint.activate([
            finishButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            finishButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -24),
            cancelButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            cancelButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -24)
        ])

        isScanning = true
        captureView.captureSession.run(configuration: configuration)
    }

    @objc private func finishScan() {
        guard isScanning else { return }
        isScanning = false
        captureView.captureSession.stop()
    }

    @objc private func cancelScan() {
        captureView.captureSession.stop()
        dismiss(animated: true) {
            self.onFinish?(nil)
        }
    }

    // MARK: - RoomCaptureViewDelegate
    func captureView(_ view: RoomCaptureView, didEndWith data: CapturedRoom, error: Error?) {
        if let error = error {
            print("❌ Scan failed:", error.localizedDescription)
            DispatchQueue.main.async {
                self.onFinish?(nil)
                self.dismiss(animated: true)
            }
            return
        }

        let fileName = "roomscan_\(UUID().uuidString).usdz"
        let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)

        do {
            try data.export(to: fileURL)
            print("✅ Scan exported successfully:", fileURL)

            let hud = UIActivityIndicatorView(style: .large)
            hud.color = .white
            hud.center = view.center
            view.addSubview(hud)
            hud.startAnimating()

            // ✅ Delay to ensure RoomCaptureView teardown completes fully
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                hud.stopAnimating()
                hud.removeFromSuperview()

                print("✅ Upload and dismiss starting…")
                self.uploadAndConfirm(fileURL: fileURL)

                // ✅ Make absolutely sure dismissal happens on main thread after upload starts
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.dismiss(animated: true) {
                        self.onFinish?(fileURL)
                        print("✅ Dismiss complete, returning to New Project")
                    }
                }
            }
        } catch {
            print("❌ Export failed:", error.localizedDescription)
            DispatchQueue.main.async {
                self.onFinish?(nil)
                self.dismiss(animated: true)
            }
        }
    }
    // MARK: - Upload & Confirm
    private func uploadAndConfirm(fileURL: URL) {
        Task {
            do {
                let data = try Data(contentsOf: fileURL)
                let filePath = "roomscans/\(fileURL.lastPathComponent)"
                try await client.storage.from("roomscans").upload(
                    filePath,
                    data: data,
                    options: FileOptions(contentType: "model/vnd.usdz+zip")
                )
                DispatchQueue.main.async {
                    self.showFinishAlert(fileURL: fileURL)
                }
            } catch {
                DispatchQueue.main.async {
                    self.showError(message: "Upload failed: \(error.localizedDescription)")
                }
            }
        }
    }

    private func showFinishAlert(fileURL: URL) {
        let alert = UIAlertController(
            title: "✅ Scan Saved",
            message: "Your room scan has been saved and uploaded successfully.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            self.dismiss(animated: true) {
                self.onFinish?(fileURL)
            }
        })
        present(alert, animated: true)
    }

    private func showError(message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

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
