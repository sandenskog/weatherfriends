import WidgetKit
import SwiftUI

// MARK: - Timeline Entry

struct WeatherEntry: TimelineEntry {
    let date: Date
    let friends: [WidgetFriendEntry]
}

// MARK: - Timeline Provider

struct WeatherTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> WeatherEntry {
        WeatherEntry(date: Date(), friends: Self.sampleEntries)
    }

    func getSnapshot(in context: Context, completion: @escaping (WeatherEntry) -> Void) {
        let entry: WeatherEntry
        if context.isPreview {
            entry = WeatherEntry(date: Date(), friends: Self.sampleEntries)
        } else {
            entry = WeatherEntry(date: Date(), friends: loadFriends())
        }
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<WeatherEntry>) -> Void) {
        let friends = loadFriends()
        let entry = WeatherEntry(date: Date(), friends: friends)
        // Uppdatera var 30:e minut — synkat med AppWeatherService 30-min TTL-cache
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }

    // MARK: - Data Loading

    private func loadFriends() -> [WidgetFriendEntry] {
        guard let defaults = UserDefaults(suiteName: "group.se.sandenskog.hotandcoldfriends"),
              let data = defaults.data(forKey: "widgetFavorites"),
              let decoded = try? JSONDecoder().decode([WidgetFriendEntry].self, from: data) else {
            return []
        }
        return decoded
    }

    // MARK: - Sample Data (for previews and placeholder)

    static let sampleEntries: [WidgetFriendEntry] = [
        WidgetFriendEntry(id: "1", displayName: "Anna", city: "Stockholm", temperatureCelsius: 22, symbolName: "sun.max.fill", temperatureColorRGB: [1.0, 0.65, 0.2]),
        WidgetFriendEntry(id: "2", displayName: "Erik", city: "Oslo", temperatureCelsius: 14, symbolName: "cloud.fill", temperatureColorRGB: [0.3, 0.75, 0.45]),
        WidgetFriendEntry(id: "3", displayName: "Sofia", city: "Barcelona", temperatureCelsius: 30, symbolName: "sun.max.fill", temperatureColorRGB: [1.0, 0.3, 0.2]),
        WidgetFriendEntry(id: "4", displayName: "Marcus", city: "London", temperatureCelsius: 12, symbolName: "cloud.rain.fill", temperatureColorRGB: [0.4, 0.7, 0.95]),
        WidgetFriendEntry(id: "5", displayName: "Lisa", city: "Reykjavik", temperatureCelsius: -2, symbolName: "cloud.snow.fill", temperatureColorRGB: [0.6, 0.85, 1.0]),
        WidgetFriendEntry(id: "6", displayName: "Johan", city: "Bangkok", temperatureCelsius: 34, symbolName: "sun.max.fill", temperatureColorRGB: [1.0, 0.3, 0.2]),
    ]
}

// MARK: - Widget Configuration

@main
struct HotAndColdFriendsWidget: Widget {
    let kind = "HotAndColdFriendsWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WeatherTimelineProvider()) { entry in
            WeatherWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Hot & Cold Friends")
        .description("Se vädret hos dina vänner.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}
