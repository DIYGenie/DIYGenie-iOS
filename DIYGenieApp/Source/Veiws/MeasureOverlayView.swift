import SwiftUI

@available(iOS 14.0, *)
struct MeasureOverlayView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var measurementResult: [Double] = []
    @State private var showARMeasure = false
    @State private var totalLength: Double?

    var body: some View {
        ZStack {
            LinearGradient(colors: [.black.opacity(0.95), .purple.opacity(0.3)],
                           startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            VStack(spacing: 30) {
                Text("AR Room Measure")
                    .font(.largeTitle.bold())
                    .foregroundColor(.white)
                    .padding(.top, 40)

                if let total = totalLength {
                    Text("Total: \(String(format: "%.1f", total)) in")
                        .font(.title2)
                        .foregroundColor(.white.opacity(0.9))
                } else {
                    Text("Tap below to start measuring.")
                        .foregroundColor(.white.opacity(0.7))
                }

                Button {
                    showARMeasure.toggle()
                } label: {
                    Text("Start Measuring")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.purple)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .padding(.horizontal, 40)
                .sheet(isPresented: $showARMeasure) {
                    ARMeasureView { measurements in
                        measurementResult = measurements
                        totalLength = measurements.reduce(0, +)
                        showARMeasure = false
                    }
                }

                if totalLength != nil {
                    Button {
                        dismiss()
                    } label: {
                        Text("Done")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.white.opacity(0.9))
                            .foregroundColor(.black)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal, 40)
                }

                Spacer()
            }
            .padding()
        }
    }
}
