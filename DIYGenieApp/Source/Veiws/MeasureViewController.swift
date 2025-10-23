import Foundation
import UIKit
import SwiftUI

/// A simple view controller that hosts the AR measurement SwiftUI view.
///
/// This controller wraps `ARMeasureView` in a `UIHostingController` and
/// exposes a callback to deliver the measured distance back to the
/// presenting context. When the user finishes measuring, the callback
/// passes the measured value (inches) to the consumer and dismisses
/// the controller.
@objc(MeasureViewController)
final class MeasureViewController: UIViewController {
    /// Callback executed when the user completes the measurement.  The
    /// callback passes the measured distance in inches.
    @objc var onComplete: ((Double) -> Void)?

    private var hostingController: UIHostingController<ARMeasureView>?

    override func viewDidLoad() {
        super.viewDidLoad()
        // Instantiate the SwiftUI view and supply a closure to handle
        // completion.  When the measurement finishes, the view will call
        // this closure with the measured value in inches.
        let measureView = ARMeasureView { [weak self] inches in
            // Forward the result to whoever presented this controller.
            self?.onComplete?(inches)
            // Dismiss the controller once the measurement is delivered.
            self?.dismiss(animated: true)
        }
        let hosting = UIHostingController(rootView: measureView)
        addChild(hosting)
        view.addSubview(hosting.view)
        hosting.view.translatesAutoresizingMaskIntoConstraints = false
        // Constrain the hosting view to fill the entire view controller's view.
        NSLayoutConstraint.activate([
            hosting.view.topAnchor.constraint(equalTo: view.topAnchor),
            hosting.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            hosting.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hosting.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
        hosting.didMove(toParent: self)
        self.hostingController = hosting
    }
}
