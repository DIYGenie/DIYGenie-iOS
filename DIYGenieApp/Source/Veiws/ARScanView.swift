import SwiftUI
import RoomPlan

/// A SwiftUI wrapper for RoomPlan’s RoomCaptureView.
/// Provides a real scan workflow using the modern RoomCapture APIs.
struct ARScanView: UIViewControllerRepresentable {
    var onFinish: (URL?) -> Void

    func makeUIViewController(context: Context) -> ARScanViewController {
        let vc = ARScanViewController()
        vc.onFinish = onFinish
        return vc
    }

    func updateUIViewController(_ uiViewController: ARScanViewController, context: Context) {}
}

final class ARScanViewController: UIViewController, RoomCaptureViewDelegate {
    var onFinish: ((URL?) -> Void)?
    private let captureView = RoomCaptureView(frame: .zero)
    private var captureSessionConfig = RoomCaptureSession.Configuration()
    private var isScanning = false
    private var captureResult: CapturedRoom?

    private lazy var startButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Start Scan", for: .normal)
        button.backgroundColor = .systemPurple
        button.tintColor = .white
        button.layer.cornerRadius = 12
        button.addTarget(self, action: #selector(startScan), for: .touchUpInside)
        return button
    }()

    private lazy var finishButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Finish Scan", for: .normal)
        button.backgroundColor = .systemGreen
        button.tintColor = .white
        button.layer.cornerRadius = 12
        button.isHidden = true
        button.addTarget(self, action: #selector(finishScan), for: .touchUpInside)
        return button
    }()

    private lazy var cancelButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Cancel", for: .normal)
        button.backgroundColor = .systemGray5
        button.tintColor = .black
        button.layer.cornerRadius = 12
        button.addTarget(self, action: #selector(cancelScan), for: .touchUpInside)
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        captureView.delegate = self
        captureView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(captureView)
        NSLayoutConstraint.activate([
            captureView.topAnchor.constraint(equalTo: view.topAnchor),
            captureView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            captureView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            captureView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        let buttonStack = UIStackView(arrangedSubviews: [startButton, finishButton, cancelButton])
        buttonStack.axis = .horizontal
        buttonStack.distribution = .fillEqually
        buttonStack.spacing = 16
        buttonStack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(buttonStack)

        NSLayoutConstraint.activate([
            buttonStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            buttonStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            buttonStack.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            buttonStack.heightAnchor.constraint(equalToConstant: 50)
        ])
    }

    // MARK: - Actions
    @objc private func startScan() {
        guard !isScanning else { return }
        isScanning = true
        startButton.isHidden = true
        finishButton.isHidden = false

        captureView.captureSession.run(configuration: captureSessionConfig)
    }

    @objc private func finishScan() {
        guard isScanning else { return }
        isScanning = false
        captureView.captureSession.stop()

        // Grab the latest capture result
        guard let result = captureView.captureResult else {
            print("❌ No captured room data found.")
            onFinish?(nil)
            return
        }

        // Export the room as a USDZ file
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("RoomScan_\(UUID().uuidString).usdz")
        do {
            try result.export(to: tempURL)
            print("✅ Room scan saved at \(tempURL.path)")
            onFinish?(tempURL)
        } catch {
            print("❌ Export failed: \(error.localizedDescription)")
            onFinish?(nil)
        }
    }

    @objc private func cancelScan() {
        if isScanning {
            captureView.captureSession.stop()
        }
        onFinish?(nil)
    }

    // MARK: - RoomCaptureViewDelegate
    func captureView(_ view: RoomCaptureView, didUpdate session: RoomCaptureSession, with data: CapturedRoomData) {
        // Optional: handle real-time updates (e.g., progress)
    }

    func captureView(_ view: RoomCaptureView, didEndWith data: CapturedRoomData, error: Error?) {
        if let error = error {
            print("❌ Capture ended with error: \(error.localizedDescription)")
            onFinish?(nil)
            return
        }
        captureResult = data.room
    }
}
