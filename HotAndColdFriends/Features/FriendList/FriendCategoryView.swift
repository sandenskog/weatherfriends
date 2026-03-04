import SwiftUI

// MARK: - WeatherCategory Enum

enum WeatherCategory: String, CaseIterable {
    case tropical = "Tropical"
    case warm = "Warm"
    case cool = "Cool"
    case cold = "Cold"
    case arctic = "Arctic"

    var label: String { rawValue }

    var emoji: String {
        switch self {
        case .tropical: return "🔥"
        case .warm: return "☀️"
        case .cool: return "🌤"
        case .cold: return "❄️"
        case .arctic: return "🧊"
        }
    }

    static func category(for celsius: Double) -> WeatherCategory {
        switch celsius {
        case ..<0:      return .arctic
        case 0..<10:    return .cold
        case 10..<20:   return .cool
        case 20..<28:   return .warm
        default:        return .tropical
        }
    }
}

// MARK: - FriendCategoryView

struct FriendCategoryView: View {
    let friendWeathers: [FriendWeather]
    @Binding var selectedFriendWeather: FriendWeather?

    private var categorized: [WeatherCategory: [FriendWeather]] {
        Dictionary(grouping: friendWeathers.filter { $0.temperatureCelsius != nil }) { fw in
            WeatherCategory.category(for: fw.temperatureCelsius!)
        }
    }

    var body: some View {
        if categorized.isEmpty {
            ContentUnavailableView(
                "Inga väderdata",
                systemImage: "cloud.fill",
                description: Text("Lägg till vänner för att se kategoriserat väder")
            )
        } else {
            ScrollView(.vertical) {
                LazyVStack(alignment: .leading, spacing: 24) {
                    ForEach(WeatherCategory.allCases, id: \.self) { category in
                        if let friends = categorized[category], !friends.isEmpty {
                            categoryRow(category: category, friends: friends)
                        }
                    }
                }
                .padding(.vertical)
            }
        }
    }

    // MARK: - Category Row

    private func categoryRow(category: WeatherCategory, friends: [FriendWeather]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("\(category.emoji) \(category.label)")
                .font(.headline)
                .padding(.horizontal)
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 12) {
                    ForEach(friends) { fw in
                        FriendWeatherCard(friendWeather: fw)
                            .onTapGesture { selectedFriendWeather = fw }
                    }
                }
                .padding(.horizontal)
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.viewAligned)
        }
    }
}

// MARK: - FriendWeatherCard

private struct FriendWeatherCard: View {
    let friendWeather: FriendWeather

    private var tempColor: Color {
        friendWeather.temperatureCelsius.map { TemperatureZone(celsius: $0).color } ?? .secondary
    }

    var body: some View {
        VStack(spacing: 8) {
            profileImage
                .frame(width: 44, height: 44)
                .clipShape(Circle())

            Text(
                friendWeather.friend.displayName
                    .components(separatedBy: " ")
                    .first ?? friendWeather.friend.displayName
            )
            .font(.caption)
            .lineLimit(1)

            Text(friendWeather.temperatureFormatted)
                .font(.title3.weight(.bold))
                .foregroundStyle(tempColor)

            Image(systemName: friendWeather.symbolName)
                .font(.body)
                .foregroundStyle(tempColor)
        }
        .frame(width: 140, height: 160)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(tempColor.opacity(0.12))
        )
    }

    @ViewBuilder
    private var profileImage: some View {
        if let urlString = friendWeather.friend.photoURL,
           let url = URL(string: urlString) {
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
