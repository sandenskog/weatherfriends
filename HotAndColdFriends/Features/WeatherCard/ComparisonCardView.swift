import SwiftUI

// MARK: - Comparison Card View

/// A shareable "Me vs You" comparison weather card.
///
/// Layout: Portrait 9:16 (390×693) with weather-themed background
/// based on the friend's weather. Left side shows the user,
/// right side shows the friend. A "VS" divider separates them.
///
/// Same ImageRenderer constraints as WeatherCardView:
/// - No `photoURL` / `AsyncImage` — gradient+initials only
/// - Self-contained rendering, no async dependencies
struct ComparisonCardView: View {

    let userWeather: FriendWeather
    let friendWeather: FriendWeather

    // MARK: - Constants

    private let cardWidth: CGFloat = 390
    private let cardHeight: CGFloat = 693
    private let cornerRadius: CGFloat = 24

    // MARK: - Computed

    private var category: WeatherCardCategory {
        // Use the friend's weather for background (the interesting comparison target)
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

            // Subtle darkening overlay for text contrast
            Color.black.opacity(0.1)

            VStack(spacing: 0) {
                Spacer()
                    .frame(height: 40)

                // Header
                Text("Weather Comparison")
                    .font(.bubbleH3)
                    .comparisonTextStyle(opacity: 0.7)

                Text(formattedDate)
                    .font(.bubbleCaption)
                    .comparisonTextStyle(opacity: 0.5)

                Spacer()
                    .frame(height: 24)

                // Side-by-side comparison
                HStack(spacing: 0) {
                    // Left side — user
                    personColumn(weather: userWeather, label: "You")

                    // VS divider
                    vsDivider

                    // Right side — friend
                    personColumn(weather: friendWeather, label: nil)
                }
                .padding(.horizontal, 16)

                Spacer()

                // Temperature difference callout
                temperatureDifference

                Spacer()
                    .frame(height: 20)

                // Branding
                Image("LogoHorizontal")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 18)
                    .foregroundStyle(.white.opacity(0.5))
                    .shadow(color: .black.opacity(0.2), radius: 2, y: 1)

                Spacer()
                    .frame(height: 16)
            }
        }
        .frame(width: cardWidth, height: cardHeight)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }

    // MARK: - Person Column

    private func personColumn(weather: FriendWeather, label: String?) -> some View {
        VStack(spacing: 8) {
            // Avatar
            AvatarView(
                displayName: weather.friend.displayName,
                temperatureCelsius: weather.temperatureCelsius,
                size: 64
            )
            .overlay(
                Circle()
                    .stroke(.white.opacity(0.5), lineWidth: 2)
            )
            .shadow(color: .black.opacity(0.25), radius: 6, y: 3)

            // Label or name
            if let label {
                Text(label)
                    .font(.bubbleCaption)
                    .comparisonTextStyle(opacity: 0.6)
            }

            // Name
            Text(weather.friend.displayName)
                .font(.bubbleH3)
                .comparisonTextStyle()
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            // City
            Text(weather.friend.city)
                .font(.bubbleCaption)
                .comparisonTextStyle(opacity: 0.7)
                .lineLimit(1)

            Spacer()
                .frame(height: 12)

            // Temperature
            Text(weather.temperatureFormatted)
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .comparisonTextStyle()

            // Weather icon
            WeatherIconMapper.icon(for: weather.symbolName, size: 28)
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.25), radius: 3, y: 1)

            // Condition
            Text(weather.conditionDescription)
                .font(.bubbleFootnote)
                .comparisonTextStyle(opacity: 0.8)
                .lineLimit(2)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - VS Divider

    private var vsDivider: some View {
        VStack(spacing: 0) {
            // Vertical line top
            Rectangle()
                .fill(.white.opacity(0.2))
                .frame(width: 1, height: 60)

            // VS circle
            ZStack {
                Circle()
                    .fill(.white.opacity(0.15))
                    .frame(width: 40, height: 40)

                Text("VS")
                    .font(.system(size: 14, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
            }

            // Vertical line bottom
            Rectangle()
                .fill(.white.opacity(0.2))
                .frame(width: 1, height: 60)
        }
        .frame(width: 44)
    }

    // MARK: - Temperature Difference

    private var temperatureDifference: some View {
        Group {
            if let userTemp = userWeather.temperatureCelsius,
               let friendTemp = friendWeather.temperatureCelsius {
                let diff = abs(userTemp - friendTemp)
                let diffFormatted = String(format: "%.0f°", diff)
                let warmer = userTemp > friendTemp

                HStack(spacing: 6) {
                    Image(systemName: warmer ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                        .font(.system(size: 16))

                    Text(diff < 1 ? "Same temperature!" : "\(diffFormatted) \(warmer ? "warmer" : "cooler") where you are")
                        .font(.bubbleCaption)
                }
                .comparisonTextStyle(opacity: 0.7)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(.white.opacity(0.1))
                .clipShape(Capsule())
            }
        }
    }
}

// MARK: - Comparison Text Style

private extension View {
    func comparisonTextStyle(opacity: Double = 1.0) -> some View {
        self
            .foregroundStyle(.white.opacity(opacity))
            .shadow(color: .black.opacity(0.3), radius: 4, y: 2)
    }
}

// MARK: - Preview

#Preview {
    let userFriend = Friend(
        authUid: "user1",
        displayName: "Richard",
        city: "Stockholm",
        cityLatitude: 59.33,
        cityLongitude: 18.07
    )
    let otherFriend = Friend(
        authUid: "user2",
        displayName: "Emma Larsson",
        city: "Barcelona",
        cityLatitude: 41.39,
        cityLongitude: 2.17
    )

    ComparisonCardView(
        userWeather: FriendWeather(friend: userFriend, weather: nil),
        friendWeather: FriendWeather(friend: otherFriend, weather: nil)
    )
}
