// Döpt AppWeatherService (inte WeatherService) för att undvika namnkollision med WeatherKit.WeatherService
import Foundation
import WeatherKit
import CoreLocation
import Observation

private actor WeatherCache {
    private struct CachedEntry {
        let weather: CurrentWeather
        let cachedAt: Date
    }
    private var store: [String: CachedEntry] = [:]
    private let ttl: TimeInterval = 30 * 60  // 30 minuter

    func get(key: String) -> CurrentWeather? {
        guard let entry = store[key],
              Date().timeIntervalSince(entry.cachedAt) < ttl else {
            store.removeValue(forKey: key)
            return nil
        }
        return entry.weather
    }

    func set(key: String, weather: CurrentWeather) {
        store[key] = CachedEntry(weather: weather, cachedAt: Date())
    }

    func clear() {
        store.removeAll()
    }
}

@Observable
@MainActor
class AppWeatherService {
    private let service = WeatherKit.WeatherService.shared
    private let cache = WeatherCache()

    /// Hämtar aktuellt väder med 30-min TTL-cache.
    /// Koordinater avrundas till 3 decimaler (ca 100m precision) som cache-nyckel.
    func currentWeather(latitude: Double, longitude: Double) async throws -> CurrentWeather {
        let key = "\(String(format: "%.3f", latitude)),\(String(format: "%.3f", longitude))"
        if let cached = await cache.get(key: key) {
            return cached
        }
        let location = CLLocation(latitude: latitude, longitude: longitude)
        let weather = try await service.weather(for: location, including: .current)
        await cache.set(key: key, weather: weather)
        return weather
    }

    /// Hämtar detaljerat väder (nuläge + timprognos + dagsprognos) utan cache.
    /// Används för expanderad vädervy — anropas sällan.
    func detailedWeather(latitude: Double, longitude: Double) async throws -> (CurrentWeather, Forecast<HourWeather>, Forecast<DayWeather>?) {
        let location = CLLocation(latitude: latitude, longitude: longitude)
        return try await service.weather(for: location, including: .current, .hourly, .daily)
    }

    /// Apple Weather-attribution — krävs av Apple att visas i appen.
    var attribution: WeatherAttribution {
        get async throws {
            try await WeatherKit.WeatherService.shared.attribution
        }
    }

    /// Rensar cachen — används vid pull-to-refresh.
    func clearCache() async {
        await cache.clear()
    }
}
