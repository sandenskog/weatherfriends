import SwiftUI

// MARK: - MyWeatherCard

/// A prominent card showing the current user's own weather,
/// displayed at the top of the friend list. Roughly double the
/// height of a regular FriendRowView (~120pt).
struct MyWeatherCard: View {
    let myWeather: FriendWeather
    let onShare: () -> Void

    private var zone: TemperatureZone {
        TemperatureZone(celsius: myWeather.temperatureCelsius ?? -99)
    }

    var body: some View {
        HStack(spacing: Spacing.md) {
            // Left side: weather info
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("My Weather")
                    .font(.bubbleCaption)
                    .foregroundStyle(Color.bubbleTextSecondary)

                Text(myWeather.friend.city)
                    .font(.bubbleBody)
                    .foregroundStyle(Color.bubbleTextPrimary)
                    .lineLimit(1)

                Text(myWeather.temperatureFormatted)
                    .font(.system(size: 44, weight: .bold, design: .rounded))
                    .foregroundStyle(zone.color)

                Text(myWeather.conditionDescription)
                    .font(.bubbleCaption)
                    .foregroundStyle(Color.bubbleTextSecondary)
                    .lineLimit(1)
            }

            Spacer()

            // Right side: icon + share button
            VStack(spacing: Spacing.sm) {
                WeatherIconMapper.icon(for: myWeather.symbolName, size: 44)
                    .foregroundStyle(zone.color)

                BubblePopButton(title: "Share My Weather") {
                    onShare()
                }
            }
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.md)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: CornerRadius.md)
                    .fill(Color.bubbleSurface)
                RoundedRectangle(cornerRadius: CornerRadius.md)
                    .fill(zone.gradient)
                    .opacity(0.12)
            }
        )
        .shadowMd()
    }
}
