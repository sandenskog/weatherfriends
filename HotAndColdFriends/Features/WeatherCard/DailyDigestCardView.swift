import SwiftUI

// MARK: - Daily Digest Card View

/// A shareable card showing a summary of all friends' current weather.
///
/// Layout: Portrait 9:16 (390×693). Header with title and date,
/// then a vertical list of friend weather rows (up to 8 visible),
/// with FriendsCast branding at the bottom.
///
/// Same ImageRenderer constraints as WeatherCardView:
/// - No `photoURL` / `AsyncImage` — gradient+initials only
/// - Self-contained rendering, no async dependencies
struct DailyDigestCardView: View {

    let friends: [FriendWeather]

    // MARK: - Constants

    private let cardWidth: CGFloat = 390
    private let cardHeight: CGFloat = 693
    private let cornerRadius: CGFloat = 24
    private let maxVisibleFriends = 8

    // MARK: - Computed

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        formatter.locale = Locale(identifier: "en_US")
        return formatter.string(from: Date())
    }

    /// Sort friends by temperature (hottest first), matching the app's main list
    private var sortedFriends: [FriendWeather] {
        friends
            .sorted { ($0.temperatureCelsius ?? -999) > ($1.temperatureCelsius ?? -999) }
    }

    private var visibleFriends: [FriendWeather] {
        Array(sortedFriends.prefix(maxVisibleFriends))
    }

    private var overflowCount: Int {
        max(0, friends.count - maxVisibleFriends)
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            // Warm gradient background
            LinearGradient(
                colors: [
                    Color(red: 1.0, green: 0.58, blue: 0.35),
                    Color(red: 1.0, green: 0.40, blue: 0.50),
                    Color(red: 0.60, green: 0.35, blue: 0.80)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack(spacing: 0) {
                Spacer()
                    .frame(height: 36)

                // Header
                header

                Spacer()
                    .frame(height: 20)

                // Friend rows
                VStack(spacing: 0) {
                    ForEach(Array(visibleFriends.enumerated()), id: \.element.id) { index, fw in
                        friendRow(fw)

                        if index < visibleFriends.count - 1 {
                            Divider()
                                .background(.white.opacity(0.15))
                                .padding(.horizontal, 16)
                        }
                    }

                    if overflowCount > 0 {
                        overflowIndicator
                    }
                }
                .padding(.vertical, 8)
                .background(.white.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal, 16)

                Spacer()

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

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 4) {
            Text("☀️ Today's Weather")
                .font(.bubbleH2)
                .digestTextStyle()

            Text(formattedDate)
                .font(.bubbleCaption)
                .digestTextStyle(opacity: 0.7)

            Text("\(friends.count) friends")
                .font(.bubbleFootnote)
                .digestTextStyle(opacity: 0.5)
        }
    }

    // MARK: - Friend Row

    private func friendRow(_ fw: FriendWeather) -> some View {
        HStack(spacing: 10) {
            // Avatar
            AvatarView(
                displayName: fw.friend.displayName,
                temperatureCelsius: fw.temperatureCelsius,
                size: 32
            )

            // Name + city
            VStack(alignment: .leading, spacing: 1) {
                Text(fw.friend.displayName)
                    .font(.bubbleButton)
                    .digestTextStyle()
                    .lineLimit(1)

                Text(fw.friend.city)
                    .font(.bubbleFootnote)
                    .digestTextStyle(opacity: 0.6)
                    .lineLimit(1)
            }

            Spacer()

            // Weather icon
            WeatherIconMapper.icon(for: fw.symbolName, size: 20)
                .foregroundStyle(.white.opacity(0.8))

            // Temperature
            Text(fw.temperatureFormatted)
                .font(.bubbleTemperatureSmall)
                .digestTextStyle()
                .frame(width: 44, alignment: .trailing)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    // MARK: - Overflow Indicator

    private var overflowIndicator: some View {
        HStack {
            Spacer()
            Text("+\(overflowCount) more")
                .font(.bubbleCaption)
                .digestTextStyle(opacity: 0.5)
            Spacer()
        }
        .padding(.vertical, 6)
    }
}

// MARK: - Digest Text Style

private extension View {
    func digestTextStyle(opacity: Double = 1.0) -> some View {
        self
            .foregroundStyle(.white.opacity(opacity))
            .shadow(color: .black.opacity(0.2), radius: 3, y: 1)
    }
}

// MARK: - Preview

#Preview {
    let sampleFriends: [FriendWeather] = [
        FriendWeather(friend: Friend(authUid: "1", displayName: "Emma Larsson", city: "Barcelona"), weather: nil),
        FriendWeather(friend: Friend(authUid: "2", displayName: "Johan Svensson", city: "Malmö"), weather: nil),
        FriendWeather(friend: Friend(authUid: "3", displayName: "Anna Berg", city: "London"), weather: nil),
        FriendWeather(friend: Friend(authUid: "4", displayName: "Erik Holm", city: "New York"), weather: nil),
        FriendWeather(friend: Friend(authUid: "5", displayName: "Sara Nilsson", city: "Tokyo"), weather: nil),
    ]

    DailyDigestCardView(friends: sampleFriends)
}
