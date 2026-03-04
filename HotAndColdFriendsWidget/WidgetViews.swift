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
            VStack(spacing: 6) {
                initialsCircle(for: friend, size: 36)
                Text(friend.displayName)
                    .font(.caption.weight(.semibold))
                    .lineLimit(1)
                HStack(spacing: 4) {
                    Image(systemName: friend.symbolName)
                        .font(.caption2)
                        .foregroundStyle(temperatureColor(for: friend))
                    if let temp = friend.temperatureCelsius {
                        Text(String(format: "%.0f\u{00B0}", temp))
                            .font(.title3.weight(.bold))
                            .foregroundStyle(temperatureColor(for: friend))
                    }
                }
                Text(friend.city)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
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
                .lineLimit(1)
            HStack(spacing: 2) {
                Image(systemName: friend.symbolName)
                    .font(.system(size: 10))
                if let temp = friend.temperatureCelsius {
                    Text(String(format: "%.0f\u{00B0}", temp))
                        .font(.caption.weight(.bold))
                }
            }
            .foregroundStyle(temperatureColor(for: friend))
            Text(friend.city)
                .font(.system(size: 9))
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 4)
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
            .fill(temperatureColor(for: friend).opacity(0.15))
        Text(initials)
            .font(.system(size: size * 0.4, weight: .semibold))
            .foregroundStyle(temperatureColor(for: friend))
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
