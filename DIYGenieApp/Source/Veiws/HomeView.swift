import SwiftUI
import ARKit
@_exported import RoomPlan


struct HomeView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text("Welcome to DIY Genie.")
                    .font(.title2)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                Text("Plan, preview, and build your next project — all with the power of AI and AR.")
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)

                NavigationLink(destination: ARScanView().ignoresSafeArea()) {
                    Text("Start AR Scan")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.purple)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .padding(.horizontal, 40)

                NavigationLink(destination: ARMeasureView { inches in
                    print("Measured: \(inches) inches")
                    // Save the measurement or navigate back if needed
                }.ignoresSafeArea()) {
                    Text("Measure Area")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.purple)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .padding(.horizontal, 40)

                Spacer()
            }
            .navigationTitle("Home")
        }
    }
}
