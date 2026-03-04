import SwiftUI

// MARK: - FriendRowView

struct FriendRowView: View {
    let friendWeather: FriendWeather

    var body: some View {
        HStack(spacing: 12) {
            profileImage

            VStack(alignment: .leading, spacing: 2) {
                Text(friendWeather.friend.displayName)
                    .font(.body.weight(.medium))
                    .lineLimit(1)
                Text(friendWeather.friend.city)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(friendWeather.temperatureFormatted)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(
                        friendWeather.temperatureCelsius.map { TemperatureZone(celsius: $0).color } ?? .bubbleTextSecondary
                    )

                WeatherIconMapper.icon(for: friendWeather.symbolName, size: 24)
                    .foregroundStyle(
                        friendWeather.temperatureCelsius.map { TemperatureZone(celsius: $0).color } ?? .bubbleTextSecondary
                    )
            }
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private var profileImage: some View {
        ZStack {
            // Animationslager bakom profilbilden
            WeatherAnimationView(condition: WeatherCondition.from(symbolName: friendWeather.symbolName))
                .frame(width: 40, height: 40)
                .clipShape(Circle())

            // Profilbild ovanpå med lätt genomskinlighet — animationen syns som en glöd runt kanten
            Group {
                if let urlString = friendWeather.friend.photoURL, let url = URL(string: urlString) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image.resizable().scaledToFill()
                        default:
                            initialsCircle
                        }
                    }
                } else {
                    initialsCircle
                }
            }
            .frame(width: 34, height: 34)
            .clipShape(Circle())
        }
    }

    private var initialsCircle: some View {
        ZStack {
            Circle()
                .fill(Color(.systemGray5))
            Text(initials(from: friendWeather.friend.displayName))
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
        }
    }

    private func initials(from name: String) -> String {
        let parts = name.split(separator: " ")
        let letters = parts.prefix(2).compactMap { $0.first.map { String($0) } }
        return letters.joined().uppercased()
    }
}
