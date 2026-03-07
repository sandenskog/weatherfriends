import SwiftUI

// MARK: - Weather Card View

/// A shareable weather card displaying a friend's current weather.
///
/// Layout: Portrait 9:16 (390x693 logical points) with weather-themed
/// background, avatar, name, city, temperature, weather icon,
/// condition description, date, and FriendsCast branding.
///
/// Note: `photoURL` is intentionally NOT used for the avatar because
/// `ImageRenderer` cannot wait for `AsyncImage` to load. The gradient
/// + initials approach is consistent and always renders correctly.
struct WeatherCardView: View {

    let friendWeather: FriendWeather

    // MARK: - Constants

    private let cardWidth: CGFloat = 390
    private let cardHeight: CGFloat = 693
    private let cornerRadius: CGFloat = 24

    // MARK: - Computed

    private var category: WeatherCardCategory {
        WeatherCardCategory.category(for: friendWeather.symbolName)
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        formatter.locale = Locale(identifier: "en_US")
        return formatter.string(from: Date())
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            WeatherCardCategory.background(for: category)

            VStack(spacing: 8) {
                Spacer()
                    .frame(minHeight: 60)

                // Avatar — gradient + initials only (no photoURL)
                AvatarView(
                    displayName: friendWeather.friend.displayName,
                    temperatureCelsius: friendWeather.temperatureCelsius,
                    size: 80
                )
                .overlay(
                    Circle()
                        .stroke(.white.opacity(0.6), lineWidth: 3)
                )
                .shadow(color: .black.opacity(0.3), radius: 8, y: 4)

                // Name
                Text(friendWeather.friend.displayName)
                    .font(.bubbleH1)
                    .cardTextStyle()

                // City
                Text(friendWeather.friend.city)
                    .font(.bubbleBody)
                    .cardTextStyle(opacity: 0.8)

                Spacer()
                    .frame(height: 16)

                // Temperature
                Text(friendWeather.temperatureFormatted)
                    .font(.system(size: 72, weight: .bold, design: .rounded))
                    .cardTextStyle()

                // Weather icon
                WeatherIconMapper.icon(for: friendWeather.symbolName, size: 40)
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.3), radius: 4, y: 2)

                // Condition description
                Text(friendWeather.conditionDescription)
                    .font(.bubbleCaption)
                    .cardTextStyle()

                // Date
                Text(formattedDate)
                    .font(.bubbleCaption)
                    .cardTextStyle(opacity: 0.7)

                Spacer()

                // Branding
                Image("LogoHorizontal")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 20)
                    .foregroundStyle(.white.opacity(0.6))
                    .shadow(color: .black.opacity(0.2), radius: 2, y: 1)

                Spacer()
                    .frame(height: 16)
            }
            .padding(.horizontal, 24)
        }
        .frame(width: cardWidth, height: cardHeight)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }
}

// MARK: - Card Text Style Modifier

private extension View {
    func cardTextStyle(opacity: Double = 1.0) -> some View {
        self
            .foregroundStyle(.white.opacity(opacity))
            .shadow(color: .black.opacity(0.3), radius: 4, y: 2)
    }
}
