import SwiftUI

// MARK: - WeatherCategory Enum

enum WeatherCategory: String, CaseIterable {
    case hottest = "Hottest"
    case coldest = "Coldest"
    case windiest = "Windiest"
    case wettest = "Wettest"

    var label: String { rawValue }

    var emoji: String {
        switch self {
        case .hottest: return "🔥"
        case .coldest: return "❄️"
        case .windiest: return "💨"
        case .wettest: return "🌧"
        }
    }
}

// MARK: - FriendCategoryView

struct FriendCategoryView: View {
    let friendWeathers: [FriendWeather]
    @Binding var selectedFriendWeather: FriendWeather?

    private func ranked(for category: WeatherCategory) -> [FriendWeather] {
        let withWeather = friendWeathers.filter { $0.weather != nil }
        switch category {
        case .hottest:
            return withWeather
                .filter { $0.temperatureCelsius != nil }
                .sorted { ($0.temperatureCelsius ?? 0) > ($1.temperatureCelsius ?? 0) }
        case .coldest:
            return withWeather
                .filter { $0.temperatureCelsius != nil }
                .sorted { ($0.temperatureCelsius ?? 0) < ($1.temperatureCelsius ?? 0) }
        case .windiest:
            return withWeather
                .filter { $0.windSpeed != nil }
                .sorted { ($0.windSpeed ?? 0) > ($1.windSpeed ?? 0) }
        case .wettest:
            return withWeather
                .filter { $0.humidity != nil }
                .sorted { ($0.humidity ?? 0) > ($1.humidity ?? 0) }
        }
    }

    var body: some View {
        let withWeather = friendWeathers.filter { $0.weather != nil }
        if withWeather.isEmpty {
            ContentUnavailableView(
                "Inga väderdata",
                systemImage: "cloud.fill",
                description: Text("Lägg till vänner för att se kategoriserat väder")
            )
        } else {
            ScrollView(.vertical) {
                LazyVStack(alignment: .leading, spacing: 24) {
                    ForEach(WeatherCategory.allCases, id: \.self) { category in
                        let friends = ranked(for: category)
                        if !friends.isEmpty {
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
                        FriendWeatherCard(friendWeather: fw, category: category)
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
    var category: WeatherCategory = .hottest

    private var accentColor: Color {
        friendWeather.temperatureCelsius.map { TemperatureZone(celsius: $0).color } ?? .secondary
    }

    private var valueText: String {
        switch category {
        case .hottest, .coldest:
            return friendWeather.temperatureFormatted
        case .windiest:
            if let speed = friendWeather.windSpeed {
                return String(format: "%.0f m/s", speed)
            }
            return "—"
        case .wettest:
            if let humidity = friendWeather.humidity {
                return String(format: "%.0f%%", humidity)
            }
            return "—"
        }
    }

    private var valueIcon: String {
        switch category {
        case .hottest, .coldest:
            return friendWeather.symbolName
        case .windiest:
            return "wind"
        case .wettest:
            return "humidity.fill"
        }
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

            Text(valueText)
                .font(.title3.weight(.bold))
                .foregroundStyle(accentColor)

            Image(systemName: valueIcon)
                .font(.body)
                .foregroundStyle(accentColor)
        }
        .frame(width: 140, height: 160)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(accentColor.opacity(0.12))
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
