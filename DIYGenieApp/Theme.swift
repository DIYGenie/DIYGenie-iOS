import SwiftUI

enum Theme {
    // Screen background (Spotify-style purple gradient)
    static var screenBackground: some View {
        LinearGradient(
            gradient: Gradient(colors: [.bgStart, .bgEnd]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }

    // Card container
    static func card(_ corner: CGFloat = 18) -> some View {
        RoundedRectangle(cornerRadius: corner, style: .continuous)
            .fill(Color.surface)
            .overlay(
                RoundedRectangle(cornerRadius: corner, style: .continuous)
                    .stroke(Color.surfaceStroke, lineWidth: 1)
            )
    }

    // CTA styles
    static func primaryButton(height: CGFloat = 56, corner: CGFloat = 18) -> some View {
        RoundedRectangle(cornerRadius: corner, style: .continuous)
            .fill(Color.accent)
            .frame(height: height)
    }

    static func secondaryButton(height: CGFloat = 56, corner: CGFloat = 18) -> some View {
        RoundedRectangle(cornerRadius: corner, style: .continuous)
            .stroke(Color.surfaceStroke, lineWidth: 1)
            .background(RoundedRectangle(cornerRadius: corner).fill(Color.surface))
            .frame(height: height)
    }

    static func sectionTitle(_ text: String) -> some View {
        Text(text.uppercased())
            .font(.system(.subheadline, design: .rounded).weight(.semibold))
            .foregroundColor(.textSecondary)
            .kerning(0.6)
    }
}

