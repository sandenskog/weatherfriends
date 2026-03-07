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
    /// Falls back to a gradient with decorative illustrations if the asset is not available.
    @ViewBuilder
    static func background(for category: WeatherCardCategory) -> some View {
        if let uiImage = UIImage(named: "weather-bg-\(category.rawValue)") {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
        } else {
            illustratedBackground(for: category)
        }
    }

    // MARK: - Illustrated Backgrounds

    @ViewBuilder
    private static func illustratedBackground(for category: WeatherCardCategory) -> some View {
        ZStack {
            gradient(for: category)
            illustrationOverlay(for: category)
        }
    }

    @ViewBuilder
    private static func illustrationOverlay(for category: WeatherCardCategory) -> some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height

            switch category {
            case .clearDay:
                clearDayIllustration(width: w, height: h)
            case .clearNight:
                clearNightIllustration(width: w, height: h)
            case .partlyCloudy:
                partlyCloudyIllustration(width: w, height: h)
            case .overcast:
                overcastIllustration(width: w, height: h)
            case .rain:
                rainIllustration(width: w, height: h)
            case .snow:
                snowIllustration(width: w, height: h)
            case .thunderstorm:
                thunderstormIllustration(width: w, height: h)
            }
        }
    }

    // MARK: - Clear Day

    private static func clearDayIllustration(width w: CGFloat, height h: CGFloat) -> some View {
        ZStack {
            // Sun glow (large soft circle)
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.white.opacity(0.4),
                            Color.yellow.opacity(0.15),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: w * 0.05,
                        endRadius: w * 0.3
                    )
                )
                .frame(width: w * 0.6, height: w * 0.6)
                .position(x: w * 0.78, y: h * 0.18)

            // Sun core
            Circle()
                .fill(Color.white.opacity(0.35))
                .frame(width: w * 0.18, height: w * 0.18)
                .position(x: w * 0.78, y: h * 0.18)

            // Small cloud lower-left
            cloudShape(width: w * 0.35, height: h * 0.08)
                .fill(Color.white.opacity(0.25))
                .position(x: w * 0.25, y: h * 0.48)

            // Small cloud lower-right
            cloudShape(width: w * 0.25, height: h * 0.06)
                .fill(Color.white.opacity(0.18))
                .position(x: w * 0.7, y: h * 0.55)
        }
    }

    // MARK: - Clear Night

    private static func clearNightIllustration(width w: CGFloat, height h: CGFloat) -> some View {
        ZStack {
            // Stars (existing pattern kept via Canvas in gradient)
            // Crescent moon — large circle with a clipping circle offset
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.3))
                    .frame(width: w * 0.2, height: w * 0.2)

                Circle()
                    .fill(Color(red: 0.10, green: 0.12, blue: 0.35))
                    .frame(width: w * 0.17, height: w * 0.17)
                    .offset(x: w * 0.05, y: -w * 0.03)
            }
            .position(x: w * 0.8, y: h * 0.15)

            // Moon glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.white.opacity(0.12),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: w * 0.08,
                        endRadius: w * 0.25
                    )
                )
                .frame(width: w * 0.5, height: w * 0.5)
                .position(x: w * 0.8, y: h * 0.15)
        }
    }

    // MARK: - Partly Cloudy

    private static func partlyCloudyIllustration(width w: CGFloat, height h: CGFloat) -> some View {
        ZStack {
            // Sun peeking from behind cloud
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.yellow.opacity(0.3),
                            Color.orange.opacity(0.1),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: w * 0.04,
                        endRadius: w * 0.2
                    )
                )
                .frame(width: w * 0.45, height: w * 0.45)
                .position(x: w * 0.35, y: h * 0.15)

            // Sun core
            Circle()
                .fill(Color.white.opacity(0.35))
                .frame(width: w * 0.12, height: w * 0.12)
                .position(x: w * 0.35, y: h * 0.15)

            // Large cloud in front of sun
            cloudShape(width: w * 0.55, height: h * 0.12)
                .fill(Color.white.opacity(0.35))
                .position(x: w * 0.5, y: h * 0.28)

            // Smaller cloud offset
            cloudShape(width: w * 0.35, height: h * 0.08)
                .fill(Color.white.opacity(0.22))
                .position(x: w * 0.75, y: h * 0.38)
        }
    }

    // MARK: - Overcast

    private static func overcastIllustration(width w: CGFloat, height h: CGFloat) -> some View {
        ZStack {
            // Top cloud layer
            cloudShape(width: w * 0.6, height: h * 0.12)
                .fill(Color.white.opacity(0.25))
                .position(x: w * 0.45, y: h * 0.15)

            // Middle cloud layer
            cloudShape(width: w * 0.5, height: h * 0.1)
                .fill(Color.white.opacity(0.18))
                .position(x: w * 0.65, y: h * 0.30)

            // Lower cloud layer
            cloudShape(width: w * 0.45, height: h * 0.09)
                .fill(Color.white.opacity(0.15))
                .position(x: w * 0.3, y: h * 0.42)
        }
    }

    // MARK: - Rain

    private static func rainIllustration(width w: CGFloat, height h: CGFloat) -> some View {
        ZStack {
            // Cloud at top
            cloudShape(width: w * 0.6, height: h * 0.12)
                .fill(Color.white.opacity(0.2))
                .position(x: w * 0.5, y: h * 0.14)

            // Second cloud
            cloudShape(width: w * 0.4, height: h * 0.08)
                .fill(Color.white.opacity(0.15))
                .position(x: w * 0.75, y: h * 0.22)

            // Rain lines
            Canvas { context, size in
                let rainDrops: [(CGFloat, CGFloat, CGFloat)] = [
                    (0.20, 0.28, 0.12),
                    (0.30, 0.32, 0.10),
                    (0.40, 0.26, 0.14),
                    (0.50, 0.30, 0.11),
                    (0.60, 0.28, 0.13),
                    (0.70, 0.34, 0.10),
                    (0.35, 0.42, 0.09),
                    (0.45, 0.40, 0.12),
                    (0.55, 0.44, 0.10),
                    (0.65, 0.42, 0.11),
                    (0.25, 0.50, 0.08),
                    (0.50, 0.52, 0.10),
                ]
                for (xRatio, yRatio, lengthRatio) in rainDrops {
                    let startX = size.width * xRatio
                    let startY = size.height * yRatio
                    let length = size.height * lengthRatio

                    var path = Path()
                    // Slightly angled rain (2-degree slant)
                    path.move(to: CGPoint(x: startX, y: startY))
                    path.addLine(to: CGPoint(x: startX - 3, y: startY + length))

                    context.stroke(
                        path,
                        with: .color(.white.opacity(0.2)),
                        lineWidth: 1.5
                    )
                }
            }
        }
    }

    // MARK: - Snow

    private static func snowIllustration(width w: CGFloat, height h: CGFloat) -> some View {
        ZStack {
            // Cloud at top
            cloudShape(width: w * 0.55, height: h * 0.11)
                .fill(Color.white.opacity(0.25))
                .position(x: w * 0.5, y: h * 0.13)

            // Second cloud
            cloudShape(width: w * 0.35, height: h * 0.08)
                .fill(Color.white.opacity(0.18))
                .position(x: w * 0.78, y: h * 0.22)

            // Snowflakes (scattered dots)
            Canvas { context, size in
                let flakes: [(CGFloat, CGFloat, CGFloat)] = [
                    (0.15, 0.28, 3.0), (0.25, 0.35, 2.5),
                    (0.35, 0.30, 3.5), (0.45, 0.38, 2.8),
                    (0.55, 0.26, 3.2), (0.65, 0.33, 2.0),
                    (0.75, 0.29, 3.0), (0.85, 0.36, 2.5),
                    (0.20, 0.45, 2.2), (0.40, 0.48, 3.0),
                    (0.60, 0.44, 2.8), (0.80, 0.47, 2.0),
                    (0.30, 0.54, 2.5), (0.50, 0.56, 3.2),
                    (0.70, 0.52, 2.0), (0.10, 0.58, 1.8),
                ]
                for (xRatio, yRatio, radius) in flakes {
                    let point = CGPoint(x: size.width * xRatio, y: size.height * yRatio)
                    let rect = CGRect(
                        x: point.x - radius,
                        y: point.y - radius,
                        width: radius * 2,
                        height: radius * 2
                    )
                    context.fill(
                        Path(ellipseIn: rect),
                        with: .color(.white.opacity(0.4))
                    )
                }
            }
        }
    }

    // MARK: - Thunderstorm

    private static func thunderstormIllustration(width w: CGFloat, height h: CGFloat) -> some View {
        ZStack {
            // Dark cloud
            cloudShape(width: w * 0.6, height: h * 0.13)
                .fill(Color.white.opacity(0.15))
                .position(x: w * 0.5, y: h * 0.15)

            // Second cloud
            cloudShape(width: w * 0.4, height: h * 0.09)
                .fill(Color.white.opacity(0.1))
                .position(x: w * 0.75, y: h * 0.25)

            // Lightning bolt
            Canvas { context, size in
                let boltX = size.width * 0.48
                let boltTopY = size.height * 0.22

                var bolt = Path()
                bolt.move(to: CGPoint(x: boltX, y: boltTopY))
                bolt.addLine(to: CGPoint(x: boltX - size.width * 0.06, y: boltTopY + size.height * 0.12))
                bolt.addLine(to: CGPoint(x: boltX + size.width * 0.02, y: boltTopY + size.height * 0.12))
                bolt.addLine(to: CGPoint(x: boltX - size.width * 0.04, y: boltTopY + size.height * 0.25))
                bolt.addLine(to: CGPoint(x: boltX + size.width * 0.01, y: boltTopY + size.height * 0.14))
                bolt.addLine(to: CGPoint(x: boltX - size.width * 0.03, y: boltTopY + size.height * 0.14))
                bolt.closeSubpath()

                context.fill(
                    bolt,
                    with: .color(Color.yellow.opacity(0.35))
                )
                context.stroke(
                    bolt,
                    with: .color(Color.white.opacity(0.25)),
                    lineWidth: 1
                )

                // Lightning glow
                let glowRect = CGRect(
                    x: boltX - size.width * 0.12,
                    y: boltTopY - size.height * 0.02,
                    width: size.width * 0.24,
                    height: size.height * 0.3
                )
                context.fill(
                    Path(ellipseIn: glowRect),
                    with: .color(Color.yellow.opacity(0.06))
                )
            }
        }
    }

    // MARK: - Reusable Cloud Shape

    /// Creates a fluffy cloud shape using overlapping ellipses.
    private static func cloudShape(width: CGFloat, height: CGFloat) -> Path {
        let midX = width / 2
        let midY = height / 2

        var path = Path()

        // Main body — wide ellipse
        path.addEllipse(in: CGRect(
            x: midX - width * 0.4,
            y: midY - height * 0.15,
            width: width * 0.8,
            height: height * 0.55
        ))

        // Left bump
        path.addEllipse(in: CGRect(
            x: midX - width * 0.35,
            y: midY - height * 0.4,
            width: width * 0.35,
            height: height * 0.55
        ))

        // Center bump (tallest)
        path.addEllipse(in: CGRect(
            x: midX - width * 0.15,
            y: midY - height * 0.5,
            width: width * 0.38,
            height: height * 0.6
        ))

        // Right bump
        path.addEllipse(in: CGRect(
            x: midX + width * 0.05,
            y: midY - height * 0.35,
            width: width * 0.3,
            height: height * 0.5
        ))

        return path.offsetBy(dx: -midX, dy: -midY)
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
