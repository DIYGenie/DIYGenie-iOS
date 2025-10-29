import UIKit

final class MeasureViewController: UIViewController {

    private var overlay: MeasureOverlayView!

    override func viewDidLoad() {
        super.viewDidLoad()
        setupOverlay()
    }

    private func setupOverlay() {
        overlay = MeasureOverlayView(frame: view.bounds)
        overlay.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(overlay)
    }

    func updateOverlayRect(_ rect: CGRect) {
        overlay.updatePath(with: rect)
    }
}
