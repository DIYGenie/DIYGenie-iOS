import SwiftUI
import UIKit

private extension Color {
    init(hex: String) {
        var s = hex.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "#", with: "")
        if s.count == 3 { s = s.map { "\($0)\($0)" }.joined() } // short hex to long
        let scanner = Scanner(string: s)
        var rgb: UInt64 = 0
        scanner.scanHexInt64(&rgb)
        let r = Double((rgb >> 16) & 0xFF) / 255.0
        let g = Double((rgb >> 8) & 0xFF) / 255.0
        let b = Double(rgb & 0xFF) / 255.0
        self = Color(red: r, green: g, blue: b)
    }

    static func asset(_ name: String, fallback: Color) -> Color {
        if let ui = UIColor(named: name) { return Color(ui) }
        return fallback
    }
}

/// Spotify-style purple gradient + surfaces, with **asset fallback** so the screen never goes black.
extension Color {
    // Palette (match your Asset names exactly)
    static let bgStart       = asset("BGStart",       fallback: Color(hex: "#0F0A1F"))
    static let bgEnd         = asset("BGEnd",         fallback: Color(hex: "#1A093E"))
    static let surface       = asset("Surface",       fallback: Color(hex: "#251C38"))
    static let surfaceStroke = asset("SurfaceStroke", fallback: Color(hex: "#3D2E57"))
    static let accent        = asset("Accent",        fallback: Color(hex: "#9B5CFF"))
    static let accentSoft    = asset("AccentSoft",    fallback: Color(hex: "#B58BFF"))
    static let textPrimary   = asset("TextPrimary",   fallback: Color(hex: "#FFFFFF"))
    static let textSecondary = asset("TextSecondary", fallback: Color(hex: "#C9C4D4"))
}

