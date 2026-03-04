import SwiftUI

// MARK: - TemperatureZone

/// Maps a Celsius temperature to one of 5 climate zones, each with
/// a canonical color and gradient from the Bubble Pop design system.
enum TemperatureZone: String, CaseIterable {
    case tropical
    case warm
    case cool
    case cold
    case arctic

    // MARK: Initializer

    /// Derive a zone from a Celsius reading.
    ///
    /// - Tropical: > 28°C
    /// - Warm:     20–28°C
    /// - Cool:     10–19.9°C
    /// - Cold:      0–9.9°C
    /// - Arctic:  < 0°C
    init(celsius: Double) {
        switch celsius {
        case let t where t > 28: self = .tropical
        case 20...28:            self = .warm
        case 10..<20:            self = .cool
        case 0..<10:             self = .cold
        default:                 self = .arctic
        }
    }

    // MARK: Color

    /// The canonical solid color for this temperature zone.
    var color: Color {
        switch self {
        case .tropical: return .tempTropical
        case .warm:     return .tempWarm
        case .cool:     return .tempCool
        case .cold:     return .tempCold
        case .arctic:   return .tempArctic
        }
    }

    // MARK: Gradient

    /// A two-color gradient suitable for avatars, widgets and backgrounds.
    var gradient: LinearGradient {
        let colors: [Color]
        switch self {
        case .tropical: colors = [.tempTropical, Color(hex: 0xFF8E6B)]
        case .warm:     colors = [.tempWarm, Color(hex: 0xFFD93D)]
        case .cool:     colors = [.tempCool, Color(hex: 0x6B9FE8)]
        case .cold:     colors = [.tempCold, Color(hex: 0x4A6CF7)]
        case .arctic:   colors = [.tempArctic, Color(hex: 0x7B61FF)]
        }
        return LinearGradient(
            colors: colors,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    // MARK: Label

    /// Human-readable zone name (e.g. "Tropical").
    var label: String {
        rawValue.capitalized
    }
}
