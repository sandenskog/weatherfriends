import SwiftUI
import WidgetKit

// MARK: - Entry View (delegerar till rätt storlek)

struct WeatherWidgetEntryView: View {
    let entry: WeatherEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(friend: entry.friends.first)
        case .systemMedium:
            MediumWidgetView(friends: Array(entry.friends.prefix(4)))
        default:
            LargeWidgetView(friends: Array(entry.friends.prefix(6)))
        }
    }
}

// MARK: - Small Widget (1 favorit)

struct SmallWidgetView: View {
    let friend: WidgetFriendEntry?

    var body: some View {
        if let friend {
            ZStack {
                zoneGradient(celsius: friend.temperatureCelsius)
                    .ignoresSafeArea()

                VStack(spacing: 6) {
                    initialsCircle(for: friend, size: 36)
                    Text(friend.displayName)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                    HStack(spacing: 4) {
                        Image(systemName: friend.symbolName)
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.85))
                        if let temp = friend.temperatureCelsius {
                            Text(String(format: "%.0f\u{00B0}", temp))
                                .font(.title3.weight(.bold))
                                .foregroundStyle(.white)
                        }
                    }
                    Text(friend.city)
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.8))
                        .lineLimit(1)
                }
            }
            .widgetURL(URL(string: "hotandcold://friend/\(friend.id)")!)
        } else {
            emptyState
        }
    }
}

// MARK: - Medium Widget (3-4 favoriter)

struct MediumWidgetView: View {
    let friends: [WidgetFriendEntry]

    var body: some View {
        if friends.isEmpty {
            emptyState
        } else {
            HStack(spacing: 0) {
                ForEach(friends, id: \.id) { friend in
                    Link(destination: URL(string: "hotandcold://friend/\(friend.id)")!) {
                        FriendWidgetCell(friend: friend)
                    }
                    if friend.id != friends.last?.id {
                        Divider()
                    }
                }
            }
        }
    }
}

// MARK: - Large Widget (alla 6 favoriter)

struct LargeWidgetView: View {
    let friends: [WidgetFriendEntry]

    var body: some View {
        if friends.isEmpty {
            emptyState
        } else {
            VStack(spacing: 4) {
                Text("Hot & Cold Friends")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.bottom, 2)

                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 8) {
                    ForEach(friends, id: \.id) { friend in
                        Link(destination: URL(string: "hotandcold://friend/\(friend.id)")!) {
                            FriendWidgetCell(friend: friend)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Shared Components

struct FriendWidgetCell: View {
    let friend: WidgetFriendEntry

    var body: some View {
        VStack(spacing: 4) {
            initialsCircle(for: friend, size: 32)
            Text(friend.displayName)
                .font(.caption2.weight(.medium))
                .foregroundStyle(.white)
                .lineLimit(1)
            HStack(spacing: 2) {
                Image(systemName: friend.symbolName)
                    .font(.system(size: 10))
                if let temp = friend.temperatureCelsius {
                    Text(String(format: "%.0f\u{00B0}", temp))
                        .font(.caption.weight(.bold))
                }
            }
            .foregroundStyle(.white.opacity(0.9))
            Text(friend.city)
                .font(.system(size: 9))
                .foregroundStyle(.white.opacity(0.75))
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
        .padding(.horizontal, 4)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(zoneGradient(celsius: friend.temperatureCelsius).opacity(0.85))
        )
        .padding(2)
    }
}

// MARK: - Helpers

private func initialsCircle(for friend: WidgetFriendEntry, size: CGFloat) -> some View {
    let initials = friend.displayName.components(separatedBy: " ")
        .prefix(2)
        .compactMap { $0.first.map(String.init) }
        .joined()
    return ZStack {
        Circle()
            .fill(
                LinearGradient(
                    colors: [Color.white.opacity(0.3), Color.white.opacity(0.1)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        Text(initials)
            .font(.system(size: size * 0.4, weight: .semibold))
            .foregroundStyle(.white)
    }
    .frame(width: size, height: size)
}

private func temperatureColor(for friend: WidgetFriendEntry) -> Color {
    Color(
        red: friend.temperatureColorRGB[safe: 0] ?? 0.6,
        green: friend.temperatureColorRGB[safe: 1] ?? 0.6,
        blue: friend.temperatureColorRGB[safe: 2] ?? 0.6
    )
}

// MARK: - TemperatureZone Gradient Helper (widget-lokal)

private func zoneGradient(celsius: Double?) -> LinearGradient {
    guard let c = celsius else {
        return LinearGradient(
            colors: [Color(widgetHex: 0x4A6CF7), Color(widgetHex: 0x7B61FF)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    let colors: [Color]
    switch c {
    case let t where t > 28:
        colors = [Color(widgetHex: 0xFF6B6B), Color(widgetHex: 0xFF8E6B)]
    case 20...28:
        colors = [Color(widgetHex: 0xFFB347), Color(widgetHex: 0xFFD93D)]
    case 10..<20:
        colors = [Color(widgetHex: 0x6BCB77), Color(widgetHex: 0x6B9FE8)]
    case 0..<10:
        colors = [Color(widgetHex: 0x6B9FE8), Color(widgetHex: 0x4A6CF7)]
    default:
        colors = [Color(widgetHex: 0x4A6CF7), Color(widgetHex: 0x7B61FF)]
    }
    return LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
}

private extension Color {
    init(widgetHex hex: UInt) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
    }
}

private var emptyState: some View {
    VStack(spacing: 8) {
        Image(systemName: "person.3")
            .font(.title2)
            .foregroundStyle(.secondary)
        Text("Inga favoriter")
            .font(.caption)
            .foregroundStyle(.secondary)
        Text("Markera vänner som favoriter i appen")
            .font(.caption2)
            .foregroundStyle(.tertiary)
            .multilineTextAlignment(.center)
    }
}

// MARK: - Array Safe Subscript

private extension Array {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

// MARK: - Previews

#Preview("Small", as: .systemSmall) {
    HotAndColdFriendsWidget()
} timeline: {
    WeatherEntry(date: Date(), friends: WeatherTimelineProvider.sampleEntries)
}

#Preview("Medium", as: .systemMedium) {
    HotAndColdFriendsWidget()
} timeline: {
    WeatherEntry(date: Date(), friends: WeatherTimelineProvider.sampleEntries)
}

#Preview("Large", as: .systemLarge) {
    HotAndColdFriendsWidget()
} timeline: {
    WeatherEntry(date: Date(), friends: WeatherTimelineProvider.sampleEntries)
}
