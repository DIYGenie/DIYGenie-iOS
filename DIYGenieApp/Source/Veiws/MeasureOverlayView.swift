import SwiftUI

@available(iOS 15.0, *)
struct MeasureOverlayView: View {
    @State private var measuredWidth: Double?
    @State private var measuredHeight: Double?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            ARMeasureView { width, height in
                self.measuredWidth = width
                self.measuredHeight = height
            }
            .edgesIgnoringSafeArea(.all)

            VStack {
                Spacer()
                if let width = measuredWidth, let height = measuredHeight {
                    VStack(spacing: 4) {
                        Text("Width: \(String(format: "%.1f", width)) in")
                        Text("Height: \(String(format: "%.1f", height)) in")
                    }
                    .font(.system(size: 16, weight: .medium))
                    .padding()
                    .background(Color.black.opacity(0.6))
                    .cornerRadius(12)
                    .foregroundColor(.white)
                    .padding(.bottom, 20)
                }
            }
        }
    }
}
