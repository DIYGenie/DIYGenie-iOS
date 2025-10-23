import SwiftUI

/// Presents the ARMeasureView with an instructional overlay.
@available(iOS 14.0, *)
struct MeasureOverlayView: View {
    /// Called when the user finishes measuring.  Passes the distance in inches.
    var onComplete: (Double) -> Void

    @State private var showOverlay = true

    var body: some View {
        ZStack(alignment: .top) {
            ARMeasureView { inches in
                onComplete(inches)
            }
            if showOverlay {
                Text("Tap two points to measure")
                    .foregroundColor(.white)
                    .padding(12)
                    .background(Color.black.opacity(0.6))
                    .cornerRadius(10)
                    .padding(.top, 40)
                    .onAppear {
                        // Hide the overlay after a few seconds if desired
                        DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                            withAnimation { showOverlay = false }
                        }
                    }
            }
        }
        .ignoresSafeArea()
    }
}
