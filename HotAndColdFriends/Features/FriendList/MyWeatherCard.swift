import SwiftUI

// MARK: - MyWeatherCard

/// Minimal weather display for use inside non-sky contexts (e.g. widgets, cards).
/// In the main app the hero weather is rendered directly in FriendsTabView on sky.
struct MyWeatherCard: View {
    let myWeather: FriendWeather
    let onShare: () -> Void

    private var zone: TemperatureZone {
        TemperatureZone(celsius: myWeather.temperatureCelsius ?? -99)
    }

    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(myWeather.friend.city)
                    .font(.atmosphereCity)
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                Text(myWeather.temperatureFormatted)
                    .font(.system(size: 40, weight: .heavy, design: .rounded))
                    .foregroundStyle(zone.color)

                Text(myWeather.conditionDescription)
                    .font(.atmosphereFriendCity)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            VStack(spacing: 12) {
                Image(systemName: myWeather.symbolName)
                    .symbolRenderingMode(.multicolor)
                    .font(.system(size: 36))

                Button(action: onShare) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .frame(width: 32, height: 32)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                }
            }
        }
        .padding(16)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}
