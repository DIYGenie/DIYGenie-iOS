
import Foundation
import UIKit
import SwiftUI

@available(iOS 15.0, *)
@objc(MeasureViewController)
final class MeasureViewController: UIViewController {

    /// Callback when measurement completes, returns width + height in inches
    @objc var onComplete: ((Double, Double) -> Void)?

    private var hostingController: UIHostingController<ARMeasureView>?

    override func viewDidLoad() {
        super.viewDidLoad()

        // ✅ Create ARMeasureView with placeholders (safe defaults)
        let measureView = ARMeasureView(
            projectId: "temp-project-id",
            scanId: "temp-scan-id",
            onComplete: { [weak self] width, height in
                self?.onComplete?(width, height)
                self?.dismiss(animated: true)
            }
        )

        // ✅ Host it inside UIKit
        let hosting = UIHostingController(rootView: measureView)
        addChild(hosting)
        hosting.view.frame = view.bounds
        hosting.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(hosting.view)
        hosting.didMove(toParent: self)
        self.hostingController = hosting
    }
}
