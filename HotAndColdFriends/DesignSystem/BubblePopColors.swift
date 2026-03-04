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

// MARK: - Bubble Pop Color Palette

extension Color {

    // MARK: Temperature Scale

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

    // MARK: Brand

    /// Primary brand color (#FF6B8A)
    static let bubblePrimary = Color(hex: 0xFF6B8A)

    /// Primary dark variant (#E85577)
    static let bubblePrimaryDark = Color(hex: 0xE85577)

    /// Secondary brand color (#FF8E6B)
    static let bubbleSecondary = Color(hex: 0xFF8E6B)

    /// Accent color (#FFD93D)
    static let bubbleAccent = Color(hex: 0xFFD93D)

    // MARK: UI

    /// App background (#F0F4FF)
    static let bubbleBg = Color(hex: 0xF0F4FF)

    /// Surface / card background (#FFFFFF)
    static let bubbleSurface = Color(hex: 0xFFFFFF)

    /// Surface hover state (#F7F9FF)
    static let bubbleSurfaceHover = Color(hex: 0xF7F9FF)

    /// Default border (#E8ECF4)
    static let bubbleBorder = Color(hex: 0xE8ECF4)

    /// Strong border (#C0C8D8)
    static let bubbleBorderStrong = Color(hex: 0xC0C8D8)

    /// Primary text (#2D3142)
    static let bubbleTextPrimary = Color(hex: 0x2D3142)

    /// Secondary text (#8892A8)
    static let bubbleTextSecondary = Color(hex: 0x8892A8)

    /// Muted text (#B0BFD6)
    static let bubbleTextMuted = Color(hex: 0xB0BFD6)

    // MARK: Chat

    /// Chat bubble gradient start — own messages (#FF6B8A)
    static let chatMineStart = Color(hex: 0xFF6B8A)

    /// Chat bubble gradient end — own messages (#FF8E6B)
    static let chatMineEnd = Color(hex: 0xFF8E6B)

    /// Chat bubble background — others' messages (#FFFFFF)
    static let chatOtherBg = Color(hex: 0xFFFFFF)

    /// Chat bubble border — others' messages (#E8ECF4)
    static let chatOtherBorder = Color(hex: 0xE8ECF4)

    // MARK: Semantic

    /// Success state (#6BCB77)
    static let bubbleSuccess = Color(hex: 0x6BCB77)

    /// Warning state (#FFB347)
    static let bubbleWarning = Color(hex: 0xFFB347)

    /// Error state (#FF6B6B)
    static let bubbleError = Color(hex: 0xFF6B6B)

    /// Favorite / heart (#FF6B8A)
    static let bubbleFavorite = Color(hex: 0xFF6B8A)
}

// MARK: - Gradients

extension LinearGradient {
    /// Chat gradient for own messages (135°, primary → secondary)
    static var chatMine: LinearGradient {
        LinearGradient(
            colors: [.chatMineStart, .chatMineEnd],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}
