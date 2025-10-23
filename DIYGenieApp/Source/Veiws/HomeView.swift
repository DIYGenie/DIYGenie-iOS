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

                NavigationLink(destination: MeasureOverlayView { inches in
                    print("Measured \(inches) inches")
                    // Save the measurement
                }.ignoresSafeArea()) {
                    Text("Measure Area")
                    // ...button styling...
                }
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

