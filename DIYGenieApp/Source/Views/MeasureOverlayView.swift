import UIKit

final class MeasureOverlayView: UIView {

    private let overlayLayer = CAShapeLayer()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupOverlay()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupOverlay()
    }

    private func setupOverlay() {
        backgroundColor = .clear
        autoresizingMask = [.flexibleWidth, .flexibleHeight]
        isUserInteractionEnabled = false

        overlayLayer.strokeColor = UIColor.systemBlue.cgColor
        overlayLayer.fillColor = UIColor.clear.cgColor
        overlayLayer.lineWidth = 2.0
        layer.addSublayer(overlayLayer)
    }

    func updatePath(with rect: CGRect) {
        let path = UIBezierPath(rect: rect)
        overlayLayer.path = path.cgPath
    }
}
