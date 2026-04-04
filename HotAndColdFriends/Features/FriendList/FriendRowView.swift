import SwiftUI

// MARK: - FriendRowView

/// Clean borderless row for the friends glass sheet.
/// Temperature and weather icon use zone color; no card border.
struct FriendRowView: View {
    let friendWeather: FriendWeather

    // MARK: - Derived

    private var zone: TemperatureZone {
        TemperatureZone(celsius: friendWeather.temperatureCelsius ?? -99)
    }

    // MARK: - Body

    var body: some View {
        HStack(spacing: 12) {
            TemperatureRingAvatar(
                photoURL: friendWeather.friend.photoURL,
                displayName: friendWeather.friend.displayName,
                temperatureCelsius: friendWeather.temperatureCelsius,
                size: 44
            )

            VStack(alignment: .leading, spacing: 2) {
                Text(friendWeather.friend.displayName)
                    .font(.atmosphereFriendName)
                    .foregroundStyle(Color.primary)
                    .lineLimit(1)

                Text(friendWeather.friend.city)
                    .font(.atmosphereFriendCity)
                    .foregroundStyle(Color.secondary)
                    .lineLimit(1)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(friendWeather.temperatureFormatted)
                    .font(.atmosphereFriendTemp)
                    .foregroundStyle(zone.color)

                WeatherIconMapper.icon(for: friendWeather.symbolName, size: 16)
                    .foregroundStyle(zone.color)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }
}
