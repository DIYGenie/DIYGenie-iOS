import SwiftUI
import ARKit
import RealityKit

// MARK: - Overlay for live rectangular AR measurement with crosshair snapping
struct MeasureOverlayView: View {
    var projectId: String
    var scanId: String
    var onComplete: ((Double, Double) -> Void)? = nil // callback when measurement is finished
    
    @Environment(\.dismiss) private var dismiss
    @State private var measuredWidth: Double = 0
    @State private var measuredHeight: Double = 0
    @State private var showInstructions = true
    @FocusState private var keyboardFocused: Bool
    
    var body: some View {
        ZStack {
            // --- AR Measurement View ---
            ARMeasureView( 
                projectId: projectId,
                scanId: scanId,
                onComplete: { width, height in
                    measuredWidth = width
                    measuredHeight = height
                    onComplete?(width, height)
                    dismiss()
                }
            )
            .ignoresSafeArea()
            
            // --- Live Crosshair Overlay ---
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    VStack {
                        Text(String(format: "W: %.1f in | H: %.1f in", measuredWidth, measuredHeight))
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(12)
                            .background(Color.black.opacity(0.6))
                            .cornerRadius(8)
                            .padding(.bottom, 30)
                    }
                    Spacer()
                }
            }
        }
        .background(Color.black.edgesIgnoringSafeArea(.all))
    }
}
