import SwiftUI

// MARK: - Weather Card Category

/// Categories for weather card backgrounds.
/// Each category maps to a set of WeatherIconMapper asset names
/// and provides a gradient background (with asset fallback).
enum WeatherCardCategory: String, CaseIterable {
    case clearDay
    case clearNight
    case partlyCloudy
    case overcast
    case rain
    case snow
    case thunderstorm

    // MARK: - Symbol Mapping

    /// Maps a WeatherKit SF Symbol name to a card background category.
    /// Uses `WeatherIconMapper.assetName(for:)` first, then matches
    /// the asset name to the appropriate category. Defaults to `.overcast`.
    static func category(for symbolName: String) -> WeatherCardCategory {
        guard let assetName = WeatherIconMapper.assetName(for: symbolName) else {
            return .overcast
        }

        switch assetName {
        case "sun-clear":
            return .clearDay
        case "moon-clear", "cloud-moon":
            return .clearNight
        case "cloud-sun":
            return .partlyCloudy
        case "cloud-overcast", "fog", "wind":
            return .overcast
        case "rain", "heavy-rain", "drizzle":
            return .rain
        case "snow", "sleet", "hail":
            return .snow
        case "thunderstorm":
            return .thunderstorm
        default:
            return .overcast
        }
    }

    // MARK: - Background View

    /// Returns a background view for this category.
    /// Attempts to load a custom asset image first (`weather-bg-{rawValue}`).
    /// Falls back to a gradient if the asset is not available.
    @ViewBuilder
    static func background(for category: WeatherCardCategory) -> some View {
        if let uiImage = UIImage(named: "weather-bg-\(category.rawValue)") {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
        } else {
            gradient(for: category)
        }
    }

    // MARK: - Gradient Fallbacks

    @ViewBuilder
    private static func gradient(for category: WeatherCardCategory) -> some View {
        switch category {
        case .clearDay:
            LinearGradient(
                colors: [
                    Color(red: 1.0, green: 0.82, blue: 0.35),
                    Color(red: 0.55, green: 0.80, blue: 0.95)
                ],
                startPoint: .top,
                endPoint: .bottom
            )

        case .clearNight:
            ZStack {
                LinearGradient(
                    colors: [
                        Color(red: 0.10, green: 0.12, blue: 0.35),
                        Color(red: 0.30, green: 0.18, blue: 0.50)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                // Subtle stars
                Canvas { context, size in
                    let starPositions: [(CGFloat, CGFloat, CGFloat)] = [
                        (0.15, 0.10, 2.0), (0.80, 0.08, 1.5),
                        (0.25, 0.25, 1.8), (0.70, 0.20, 2.2),
                        (0.45, 0.15, 1.2), (0.90, 0.30, 1.6),
                        (0.10, 0.40, 1.4), (0.60, 0.35, 2.0),
                        (0.35, 0.45, 1.0), (0.85, 0.50, 1.8),
                        (0.50, 0.55, 1.5), (0.20, 0.60, 1.3),
                    ]
                    for (xRatio, yRatio, radius) in starPositions {
                        let point = CGPoint(x: size.width * xRatio, y: size.height * yRatio)
                        let rect = CGRect(
                            x: point.x - radius,
                            y: point.y - radius,
                            width: radius * 2,
                            height: radius * 2
                        )
                        context.fill(
                            Path(ellipseIn: rect),
                            with: .color(.white.opacity(0.5))
                        )
                    }
                }
            }

        case .partlyCloudy:
            LinearGradient(
                colors: [
                    Color(red: 0.90, green: 0.93, blue: 0.98),
                    Color(red: 0.55, green: 0.78, blue: 0.95)
                ],
                startPoint: .top,
                endPoint: .bottom
            )

        case .overcast:
            LinearGradient(
                colors: [
                    Color(red: 0.82, green: 0.84, blue: 0.87),
                    Color(red: 0.60, green: 0.63, blue: 0.68)
                ],
                startPoint: .top,
                endPoint: .bottom
            )

        case .rain:
            LinearGradient(
                colors: [
                    Color(red: 0.35, green: 0.42, blue: 0.55),
                    Color(red: 0.22, green: 0.28, blue: 0.40)
                ],
                startPoint: .top,
                endPoint: .bottom
            )

        case .snow:
            LinearGradient(
                colors: [
                    Color(red: 0.95, green: 0.97, blue: 1.0),
                    Color(red: 0.75, green: 0.85, blue: 0.95)
                ],
                startPoint: .top,
                endPoint: .bottom
            )

        case .thunderstorm:
            LinearGradient(
                colors: [
                    Color(red: 0.25, green: 0.15, blue: 0.35),
                    Color(red: 0.18, green: 0.20, blue: 0.28)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }
}
