import SwiftUI

/// Reusable visual primitives for DIY Genie.
enum Theme {
    // Screen background (Spotify-style purple gradient)
    static var screenBackground: some View {
        LinearGradient(
            gradient: Gradient(colors: [.BgStart, .BgEnd]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }

    // Card container
    static func card(corner: CGFloat = 18) -> some View {
        RoundedRectangle(cornerRadius: corner, style: .continuous)
            .fill(Color.Surface)
            .overlay(
                RoundedRectangle(cornerRadius: corner, style: .continuous)
                    .stroke(Color.SurfaceStroke, lineWidth: 1)
            )
    }

    // Primary CTA button background
    static func primaryButton(height: CGFloat = 56, corner: CGFloat = 18) -> some View {
        RoundedRectangle(cornerRadius: corner, style: .continuous)
            .fill(Color.Accent)
            .frame(height: height)
    }

    // Secondary (outlined) button background
    static func secondaryButton(height: CGFloat = 56, corner: CGFloat = 18) -> some View {
        RoundedRectangle(cornerRadius: corner, style: .continuous)
            .stroke(Color.SurfaceStroke, lineWidth: 1)
            .background(
                RoundedRectangle(cornerRadius: corner)
                    .fill(Color.Surface)
            )
            .frame(height: height)
    }

    // Section title styling
    static func sectionTitle(_ text: String) -> some View {
        Text(text.uppercased())
            .font(.system(.subheadline, design: .rounded).weight(.semibold))
            .foregroundColor(.TextSecondary)
            .kerning(0.6)
    }
}
