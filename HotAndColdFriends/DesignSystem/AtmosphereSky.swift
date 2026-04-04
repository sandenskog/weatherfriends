import SwiftUI

// MARK: - SkyMood

/// Represents a weather-derived sky palette for MeshGradient backgrounds.
enum SkyMood: Equatable {
    case sunny
    case partlyCloudy
    case overcast
    case rain
    case snow
    case thunder
    case nightClear
    case nightCloudy

    // MARK: Factory

    /// Derive the appropriate sky mood from a WeatherKit symbolName and day/night flag.
    static func from(symbolName: String, isDaytime: Bool = true) -> SkyMood {
        let s = symbolName.lowercased()

        // Thunderstorm
        if s.contains("bolt") { return .thunder }

        // Snow / sleet / hail
        if s.contains("snow") || s.contains("sleet") || s.contains("hail") || s.contains("snowflake") {
            return .snow
        }

        // Rain / drizzle
        if s.contains("rain") || s.contains("drizzle") || s.contains("shower") {
            return isDaytime ? .rain : .nightCloudy
        }

        // Fog / smoke / wind / overcast / heavy cloud
        if s.contains("fog") || s.contains("smoke") || s.contains("overcast") || s.contains("cloud") && !s.contains("sun") && !s.contains("moon") {
            return isDaytime ? .overcast : .nightCloudy
        }

        // Partly cloudy
        if s.contains("cloud") {
            return isDaytime ? .partlyCloudy : .nightCloudy
        }

        // Clear / sunny
        if isDaytime {
            return .sunny
        } else {
            return .nightClear
        }
    }

    // MARK: Mesh Colors

    /// Four mesh gradient colors: [topLeft, topRight, bottomRight, bottomLeft]
    var meshColors: [Color] {
        switch self {
        case .sunny:
            return [
                Color(hex: 0x1A85E0), // top-left — blue
                Color(hex: 0x4AABF0), // top-right — cornflower
                Color(hex: 0xF7C94A), // bottom-right — warm gold
                Color(hex: 0xFFF8E8)  // bottom-left — cream
            ]
        case .partlyCloudy:
            return [
                Color(hex: 0x5B8DB8), // top-left — steel blue
                Color(hex: 0x7AA8C8), // top-right
                Color(hex: 0x9BA8B0), // bottom-right — warm grey
                Color(hex: 0xC8C4B8)  // bottom-left
            ]
        case .overcast:
            return [
                Color(hex: 0x3A4A5C), // top-left — slate
                Color(hex: 0x4A5F72), // top-right
                Color(hex: 0x6B7F8F), // bottom-right — grey-blue
                Color(hex: 0x8A9AA8)  // bottom-left
            ]
        case .rain:
            return [
                Color(hex: 0x3A4A5C),
                Color(hex: 0x4A5F72),
                Color(hex: 0x6B7F8F),
                Color(hex: 0x8A9AA8)
            ]
        case .snow:
            return [
                Color(hex: 0xB8D4E8), // top-left — ice blue
                Color(hex: 0xD0E4F0), // top-right — pale
                Color(hex: 0xF0F4F8), // bottom-right — white
                Color(hex: 0xE8EEF4)  // bottom-left
            ]
        case .thunder:
            return [
                Color(hex: 0x1A1A2E), // top-left — near-black
                Color(hex: 0x2D1B4E), // top-right — dark purple
                Color(hex: 0x2A3040), // bottom-right — dark slate
                Color(hex: 0x1E2840)  // bottom-left
            ]
        case .nightClear:
            return [
                Color(hex: 0x0D1B4E), // top-left — deep indigo
                Color(hex: 0x1A2A6C), // top-right — midnight
                Color(hex: 0x0D1535), // bottom-right — dark blue
                Color(hex: 0x0A1228)  // bottom-left
            ]
        case .nightCloudy:
            return [
                Color(hex: 0x151520), // top-left — near-black
                Color(hex: 0x1E2535), // top-right — dark slate
                Color(hex: 0x1A2030), // bottom-right
                Color(hex: 0x141820)  // bottom-left
            ]
        }
    }

    /// Whether sky text should be white. Snow uses dark text.
    var usesWhiteText: Bool {
        self != .snow
    }

    /// A simple two-stop linear gradient fallback (iOS 17 and earlier).
    var fallbackGradient: LinearGradient {
        let colors = meshColors
        return LinearGradient(
            colors: [colors[0], colors[2]],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// MARK: - AtmosphereSkyBackground

/// Full-screen sky background.
/// Uses iOS 18 MeshGradient with subtle animation.
/// Falls back to LinearGradient on iOS 17.
struct AtmosphereSkyBackground: View {
    let mood: SkyMood

    @State private var animationPhase: Bool = false

    private let animationDuration: Double = 8.0

    var body: some View {
        Group {
            if #available(iOS 18.0, *) {
                meshBackground
            } else {
                mood.fallbackGradient
            }
        }
        .onAppear {
            withAnimation(
                .easeInOut(duration: animationDuration)
                .repeatForever(autoreverses: true)
            ) {
                animationPhase = true
            }
        }
        .onChange(of: mood) { _, _ in
            // Reset animation phase on mood change
            animationPhase = false
            withAnimation(
                .easeInOut(duration: animationDuration)
                .repeatForever(autoreverses: true)
            ) {
                animationPhase = true
            }
        }
    }

    @available(iOS 18.0, *)
    private var meshBackground: some View {
        let colors = mood.meshColors
        let shift: Float = animationPhase ? 0.08 : 0.0

        return MeshGradient(
            width: 2,
            height: 2,
            points: [
                [0.0 - shift, 0.0 - shift],   // top-left
                [1.0 + shift, 0.0 + shift],   // top-right
                [0.0 + shift, 1.0 + shift],   // bottom-left
                [1.0 - shift, 1.0 - shift]    // bottom-right
            ],
            colors: [
                colors[0], // top-left
                colors[1], // top-right
                colors[3], // bottom-left
                colors[2]  // bottom-right
            ]
        )
    }
}

// MARK: - View + Atmosphere Sky

extension View {
    /// Wraps the view in a ZStack with the sky background filling the whole screen.
    func atmosphereSky(mood: SkyMood) -> some View {
        ZStack {
            AtmosphereSkyBackground(mood: mood)
                .ignoresSafeArea()
            self
        }
    }
}
