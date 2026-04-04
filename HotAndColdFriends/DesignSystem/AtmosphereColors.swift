import SwiftUI

// MARK: - Hex Color Initializer

extension Color {
    init(hex: UInt, opacity: Double = 1) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: opacity
        )
    }
}

// MARK: - Atmosphere + Legacy Color Palette

extension Color {

    // MARK: Temperature Scale (identical values — TemperatureZone depends on these)

    /// Tropical — >28°C (#FF6B6B)
    static let tempTropical = Color(hex: 0xFF6B6B)

    /// Warm — 20–28°C (#FFB347)
    static let tempWarm = Color(hex: 0xFFB347)

    /// Cool — 10–20°C (#6BCB77)
    static let tempCool = Color(hex: 0x6BCB77)

    /// Cold — 0–10°C (#6B9FE8)
    static let tempCold = Color(hex: 0x6B9FE8)

    /// Arctic — <0°C (#4A6CF7)
    static let tempArctic = Color(hex: 0x4A6CF7)

    // MARK: Atmosphere Text on Sky

    /// Primary text on sky — white 95%
    static let atmosphereTextOnSky = Color.white.opacity(0.95)

    /// Secondary text on sky — white 65%
    static let atmosphereTextOnSkySecondary = Color.white.opacity(0.65)

    /// Muted text on sky — white 45%
    static let atmosphereTextOnSkyMuted = Color.white.opacity(0.45)

    // MARK: Legacy Brand Tokens (kept for any remaining consumers)

    /// Primary brand — atmosphere blue
    static let bubblePrimary = Color(hex: 0x1A85E0)

    /// Primary dark variant
    static let bubblePrimaryDark = Color(hex: 0x1260A8)

    /// Secondary brand
    static let bubbleSecondary = Color(hex: 0x4AABF0)

    /// Accent
    static let bubbleAccent = Color(hex: 0xF7C94A)

    // MARK: Legacy UI Tokens

    static let bubbleBg = Color(hex: 0xF0F5FF)
    static let bubbleSurface = Color.white
    static let bubbleSurfaceHover = Color(hex: 0xF7F9FF)
    static let bubbleBorder = Color.white.opacity(0.25)
    static let bubbleBorderStrong = Color.white.opacity(0.45)
    static let bubbleTextPrimary = Color.primary
    static let bubbleTextSecondary = Color.secondary
    static let bubbleTextMuted = Color.secondary.opacity(0.6)

    // MARK: Legacy Chat Tokens

    static let chatMineStart = Color.white.opacity(0.92)
    static let chatMineEnd = Color.white.opacity(0.88)
    static let chatOtherBg = Color.white.opacity(0.15)
    static let chatOtherBorder = Color.white.opacity(0.25)

    // MARK: Legacy Semantic Tokens

    static let bubbleSuccess = Color(hex: 0x6BCB77)
    static let bubbleWarning = Color(hex: 0xFFB347)
    static let bubbleError = Color(hex: 0xFF6B6B)
    static let bubbleFavorite = Color(hex: 0xFF6B8A)
}

// MARK: - Legacy Gradients

extension LinearGradient {
    /// Chat gradient for own messages — white glass style
    static var chatMine: LinearGradient {
        LinearGradient(
            colors: [Color.white.opacity(0.92), Color.white.opacity(0.82)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}
