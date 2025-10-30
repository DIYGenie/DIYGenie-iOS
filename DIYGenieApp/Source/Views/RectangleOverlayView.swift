//
//  RectangleOverlayView.swift
//  DIYGenieApp
//

import SwiftUI
import UIKit

struct RectangleOverlayView: View {
    let image: UIImage
    let projectId: String
    let userId: String
    var onCancel: () -> Void
    var onComplete: (CGRect) -> Void
    var onError: (Error) -> Void

    @State private var rectPosition = CGSize.zero
    @State private var rectScale: CGFloat = 1.0
    @State private var showHint = true

    var body: some View {
        ZStack {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .ignoresSafeArea()

            Rectangle()
                .strokeBorder(
                    style: StrokeStyle(lineWidth: 2, dash: [8])
                )
                .foregroundColor(Color.purple.opacity(0.9))
                .background(Color.purple.opacity(0.25))
                .frame(width: 220 * rectScale, height: 140 * rectScale)
                .offset(rectPosition)
                .shadow(color: Color.white.opacity(0.3), radius: 3)
                .gesture(dragGesture.simultaneously(with: pinchGesture))
                .animation(.easeInOut(duration: 0.2), value: rectPosition)
                .animation(.easeInOut(duration: 0.2), value: rectScale)

            if showHint {
                Text("Tap, drag, or pinch to adjust your area")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                    .padding(.top, 50)
                    .transition(.opacity)
                    .onAppear {
                        withAnimation(.easeInOut(duration: 2.5).delay(2)) {
                            showHint = false
                        }
                    }
                    .frame(maxHeight: .infinity, alignment: .top)
            }

            VStack {
                Spacer()
                HStack(spacing: 16) {
                    Button(action: onCancel) {
                        Text("Cancel")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(12)
                    }

                    Button(action: confirmSelection) {
                        Text("Confirm")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                LinearGradient(colors: [
                                    Color(red: 115/255, green: 73/255, blue: 224/255),
                                    Color(red: 146/255, green: 86/255, blue: 255/255)
                                ], startPoint: .leading, endPoint: .trailing)
                            )
                            .cornerRadius(12)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
        }
        .preferredColorScheme(.dark)
    }

    private var dragGesture: some Gesture {
        DragGesture().onChanged { value in rectPosition = value.translation }
    }

    private var pinchGesture: some Gesture {
        MagnificationGesture().onChanged { value in rectScale = min(max(value, 0.5), 2.0) }
    }

    private func confirmSelection() {
        guard let screen = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first?.windows.first?.bounds else { return }

        let rectWidth = 220 * rectScale
        let rectHeight = 140 * rectScale
        let originX = ((screen.width / 2) + rectPosition.width - (rectWidth / 2)) / screen.width
        let originY = ((screen.height / 2) + rectPosition.height - (rectHeight / 2)) / screen.height

        let normalized = CGRect(
            x: max(0, min(1, originX)),
            y: max(0, min(1, originY)),
            width: min(1, rectWidth / screen.width),
            height: min(1, rectHeight / screen.height)
        )

        onComplete(normalized)
    }
}
