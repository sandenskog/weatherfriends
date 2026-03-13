import Foundation

// MARK: - Weather Nudge Service

/// Generates short contextual nudge text for friends with interesting weather.
///
/// Returns nil for unremarkable conditions — nudges should feel special,
/// not appear on every row. The caller shows a small chip when non-nil.
enum WeatherNudgeService {

    /// Returns a short nudge string for interesting weather, or nil for ordinary conditions.
    static func nudge(for friendWeather: FriendWeather) -> String? {
        // Temperature-based nudges (highest priority)
        if let temp = friendWeather.temperatureCelsius {
            if temp >= 38 { return "🔥 Extreme heat!" }
            if temp >= 33 { return "☀️ Heatwave!" }
            if temp <= -15 { return "🥶 Extreme cold!" }
            if temp <= -5 { return "❄️ Freezing!" }
        }

        // Weather condition nudges
        let symbol = friendWeather.symbolName
        let conditionNudge = nudgeForCondition(symbol)
        if let conditionNudge { return conditionNudge }

        // Temperature + clear sky combo
        if let temp = friendWeather.temperatureCelsius {
            if temp >= 28 && isClearSky(symbol) { return "☀️ Beach weather!" }
            if temp <= 0 && isClearSky(symbol) { return "🌡️ Clear & cold!" }
        }

        return nil
    }

    // MARK: - Private

    private static func nudgeForCondition(_ symbol: String) -> String? {
        let normalized = symbol.replacingOccurrences(of: ".fill", with: "")

        switch normalized {
        case "cloud.bolt", "cloud.bolt.rain":
            return "⛈️ Thunderstorm!"
        case "cloud.snow", "snowflake":
            return "❄️ It's snowing!"
        case "cloud.heavyrain":
            return "🌧️ Heavy rain!"
        case "cloud.hail":
            return "🌨️ Hailing!"
        case "cloud.fog":
            return "🌫️ Foggy!"
        default:
            return nil
        }
    }

    private static func isClearSky(_ symbol: String) -> Bool {
        let normalized = symbol.replacingOccurrences(of: ".fill", with: "")
        return ["sun.max", "sun.min", "moon", "moon.stars"].contains(normalized)
    }
}
