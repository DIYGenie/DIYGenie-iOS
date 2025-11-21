//
//  DesignSystem.swift
//  DIYGenieApp
//
//  Design system with colors, typography, and reusable components.
//

import SwiftUI

enum DS {
    enum Colors {
        // Background
        static let background = Color(hex: 0x0D1226)
        
        // Gradient
        static let gradientTop = Color(hex: 0x7B5CFF)
        static let gradientBottom = Color(hex: 0x8A4DFF)
        
        // Accent
        static let lavenderAccent = Color(hex: 0xC7B9FF)
        
        // Card overlay
        static let cardOverlay = Color.white.opacity(0.06)
        
        // Border
        static let cardBorder = Color(hex: 0xC7B9FF).opacity(0.15)
        
        // Text
        static let textPrimary = Color.white
        static let textSecondary = Color.white.opacity(0.7)
    }
    
    enum Styles {
        // Primary button style
        static func primaryButton() -> some View {
            LinearGradient(
                gradient: Gradient(colors: [Colors.gradientTop, Colors.gradientBottom]),
                startPoint: .leading,
                endPoint: .trailing
            )
        }
        
        // Card container
        static func card() -> some View {
            RoundedRectangle(cornerRadius: 14)
                .fill(Colors.cardOverlay)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Colors.cardBorder, lineWidth: 1)
                )
        }
    }
}

extension Color {
    init(hex: UInt, alpha: Double = 1.0) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255.0,
            green: Double((hex >> 8) & 0xFF) / 255.0,
            blue: Double(hex & 0xFF) / 255.0,
            opacity: alpha
        )
    }
}

