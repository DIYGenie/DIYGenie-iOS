//
//  MeasureOverlayView.swift
//  DIYGenieApp
//
//  Created by Tye on 10/28/25.
//

import SwiftUI
import ARKit
import RealityKit

/// Overlay for live rectangular AR measurement with crosshair snapping
struct MeasureOverlayView: View {
    var onComplete: (Double, Double) -> Void  // width + height callback
    
    @Environment(\.dismiss) private var dismiss
    @State private var measuredWidth: Double = 0
    @State private var measuredHeight: Double = 0
    @State private var showInstructions = true
    
    var body: some View {
        ZStack {
            // AR measurement view
            ARMeasureView(onComplete: { width, height in
                measuredWidth = width
                measuredHeight = height
            })
            .ignoresSafeArea()

            // Live crosshair overlay
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
            
            // Instructions popup
            if showInstructions {
                VStack(spacing: 12) {
                    Text("🪜 Measure Mode")
                        .font(.headline)
                    Text("Move your camera and drag corners to outline the area you want to measure.")
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    Button("Got it") {
                        withAnimation { showInstructions = false }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color.accentColor)
                }
                .padding()
                .background(.ultraThinMaterial)
                .cornerRadius(14)
                .shadow(radius: 10)
            }
            
            // Done button
            VStack {
                Spacer()
                Button(action: {
                    onComplete(measuredWidth, measuredHeight)
                    dismiss()
                }) {
                    Text("Done Measuring")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .padding(.horizontal)
                }
                .padding(.bottom, 40)
            }
        }
    }
}
