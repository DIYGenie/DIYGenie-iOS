import SwiftUI
import ARKit
import RealityKit

/// Overlay for live rectangular AR measurement with crosshair snapping
struct MeasureOverlayView: View {
    var onComplete: ((Double, Double) -> Void)? = nil // optional callback

    @Environment(\.dismiss) private var dismiss
    @State private var measuredWidth: Double = 0
    @State private var measuredHeight: Double = 0
    @State private var showInstructions = true
    @FocusState private var keyboardFocused: Bool

    var body: some View {
        ZStack {
            // --- AR Measurement View ---
            ARMeasureView(
                projectId: "temp-project-id",
                scanId: "temp-scan-id"
            )
            .ignoresSafeArea()

            // --- Live Crosshair Overlay ---
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Image(systemName: "plus")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(Color.accentColor.opacity(0.9))
                    Spacer()
                }
                Spacer()
            }

            // --- Banner after success ---
            if measuredWidth > 0 && measuredHeight > 0 {
                VStack {
                    Text("Room scan saved ✅")
                        .font(.headline)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.black.opacity(0.7))
                        )
                        .foregroundColor(.white)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    Spacer()
                }
                .padding(.top, 40)
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        withAnimation(.easeInOut(duration: 0.5)) {
                            measuredWidth = 0
                            measuredHeight = 0
                        }
                        dismissKeyboard()
                    }
                }
            }
        }
        .onTapGesture {
            dismissKeyboard()
        }
    }

    private func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

#Preview {
    MeasureOverlayView()
}
