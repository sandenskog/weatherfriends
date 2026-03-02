import SwiftUI

// MARK: - Temperature Color Extension

extension Color {
    static func temperatureColor(celsius: Double) -> Color {
        switch celsius {
        case ..<0:
            return Color(red: 0.2, green: 0.4, blue: 1.0)   // isblå
        case 0..<10:
            return Color(red: 0.4, green: 0.6, blue: 0.9)   // kylig blå
        case 10..<20:
            return Color(red: 0.5, green: 0.7, blue: 0.5)   // neutral grön
        case 20..<28:
            return Color(red: 1.0, green: 0.6, blue: 0.2)   // varm orange
        default:
            return Color(red: 0.9, green: 0.2, blue: 0.2)   // het röd
        }
    }
}

// MARK: - FriendRowView

struct FriendRowView: View {
    let friendWeather: FriendWeather

    var body: some View {
        HStack(spacing: 12) {
            profileImage
                .frame(width: 40, height: 40)
                .clipShape(Circle())

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
                        friendWeather.temperatureCelsius.map { Color.temperatureColor(celsius: $0) } ?? .secondary
                    )

                Image(systemName: friendWeather.symbolName)
                    .font(.body)
                    .foregroundStyle(
                        friendWeather.temperatureCelsius.map { Color.temperatureColor(celsius: $0) } ?? .secondary
                    )
            }
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private var profileImage: some View {
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
