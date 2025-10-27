import SwiftUI
import UIKit
import RoomPlan

struct ARScanView: UIViewControllerRepresentable {
    var onFinish: (URL?) -> Void

    func makeUIViewController(context: Context) -> ARScanViewController {
        let vc = ARScanViewController()
        vc.onFinish = onFinish
        return vc
    }

    func updateUIViewController(_ uiViewController: ARScanViewController, context: Context) {}
}

// MARK: - Controller
final class ARScanViewController: UIViewController, RoomCaptureSessionDelegate {

    var onFinish: ((URL?) -> Void)?
    private var captureSession: RoomCaptureSession!
    private let configuration = RoomCaptureSession.Configuration()
    private var captureView: RoomCaptureView!

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupCapture()
        setupControls()
    }

    private func setupCapture() {
        // In your SDK, RoomCaptureView automatically owns its own session.
        // We’ll grab that and assign its delegate.
        captureView = RoomCaptureView(frame: view.bounds)
        captureView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(captureView)

        // Use the view’s built-in session instead of creating a separate one.
        captureSession = captureView.captureSession
        captureSession.delegate = self
    }

    private func setupControls() {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 12
        stack.distribution = .fillEqually
        stack.translatesAutoresizingMaskIntoConstraints = false

        let start = makeButton("Start", color: .systemBlue, action: #selector(startScan))
        let finish = makeButton("Finish", color: .systemGreen, action: #selector(finishScan))
        let cancel = makeButton("Cancel", color: .systemRed, action: #selector(cancelScan))

        [start, finish, cancel].forEach(stack.addArrangedSubview)
        view.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            stack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stack.heightAnchor.constraint(equalToConstant: 44),
            stack.widthAnchor.constraint(equalToConstant: 300)
        ])
    }

    private func makeButton(_ title: String, color: UIColor, action: Selector) -> UIButton {
        let b = UIButton(type: .system)
        b.setTitle(title, for: .normal)
        b.backgroundColor = color
        b.tintColor = .white
        b.layer.cornerRadius = 8
        b.addTarget(self, action: action, for: .touchUpInside)
        return b
    }

    // MARK: Actions
    @objc private func startScan() {
        do {
            try captureSession.run(configuration: configuration)
            print("✅ RoomPlan session started")
        } catch {
            print("❌ Could not start RoomPlan: \(error)")
        }
    }

    @objc private func finishScan() {
        captureSession.stop()
        // When stopped, delegate below fires with captured data
    }

    @objc private func cancelScan() {
        captureSession.stop()
        onFinish?(nil)
        dismiss(animated: true)
    }

    // MARK: Delegate
    func captureSession(_ session: RoomCaptureSession, didEndWith data: CapturedRoom?, error: Error?) {
        if let error {
            print("❌ Capture ended with error: \(error.localizedDescription)")
            onFinish?(nil)
            return
        }
        guard let room = data else {
            print("⚠️ No room data captured")
            onFinish?(nil)
            return
        }
        export(room)
    }

    // MARK: Export
    private func export(_ room: CapturedRoom) {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("RoomScan_\(UUID().uuidString).usdz")
        do {
            try room.export(to: url)  // works across all versions
            print("✅ Exported .usdz to \(url)")
            onFinish?(url)
        } catch {
            print("❌ Export failed: \(error.localizedDescription)")
            onFinish?(nil)
        }
    }
}
