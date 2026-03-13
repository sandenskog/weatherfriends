import SwiftUI

// MARK: - FriendRowView

struct FriendRowView: View {
    let friendWeather: FriendWeather

    // MARK: - Derived

    private var zone: TemperatureZone {
        TemperatureZone(celsius: friendWeather.temperatureCelsius ?? -99)
    }

    private var nudgeText: String? {
        WeatherNudgeService.nudge(for: friendWeather)
    }

    // MARK: - Body

    var body: some View {
        HStack(spacing: Spacing.md) {
            AvatarView(
                displayName: friendWeather.friend.displayName,
                temperatureCelsius: friendWeather.temperatureCelsius,
                size: 52,
                photoURL: friendWeather.friend.photoURL
            )

            VStack(alignment: .leading, spacing: 2) {
                Text(friendWeather.friend.displayName)
                    .font(.bubbleH3)
                    .foregroundStyle(Color.bubbleTextPrimary)
                    .lineLimit(1)

                Text(friendWeather.friend.city)
                    .font(.bubbleCaption)
                    .foregroundStyle(Color.bubbleTextSecondary)
                    .lineLimit(1)

                if let nudge = nudgeText {
                    Text(nudge)
                        .font(.bubbleFootnote)
                        .foregroundStyle(.white)
                        .padding(.horizontal, Spacing.sm)
                        .padding(.vertical, Spacing.xs)
                        .background(zone.color.opacity(0.85))
                        .clipShape(Capsule())
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(friendWeather.temperatureFormatted)
                    .font(.bubbleTemperature)
                    .foregroundStyle(zone.color)

                WeatherIconMapper.icon(for: friendWeather.symbolName, size: 28)
                    .foregroundStyle(zone.color)
            }
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm + Spacing.xs)
        .background(Color.bubbleSurface)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md))
        .shadowMd()
    }
}
