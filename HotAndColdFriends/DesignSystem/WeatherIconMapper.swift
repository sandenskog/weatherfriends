import SwiftUI

enum WeatherIconMapper {
    /// Mappar ett WeatherKit SF Symbol-namn till motsvarande custom asset-namn.
    /// Returnerar nil om inget custom asset matchar — caller kan falla tillbaka till SF Symbol.
    static func assetName(for symbolName: String) -> String? {
        // Normalisera: ta bort ".fill" suffix
        let normalized = symbolName.replacingOccurrences(of: ".fill", with: "")

        switch normalized {
        // Clear
        case "sun.max", "sun.min":
            return "sun-clear"
        case "moon", "moon.stars":
            return "moon-clear"

        // Partly cloudy
        case "cloud.sun":
            return "cloud-sun"
        case "cloud.moon":
            return "cloud-moon"

        // Overcast
        case "cloud", "smoke":
            return "cloud-overcast"

        // Rain
        case "cloud.rain":
            return "rain"
        case "cloud.heavyrain":
            return "heavy-rain"
        case "cloud.drizzle":
            return "drizzle"

        // Winter
        case "cloud.snow", "snowflake":
            return "snow"
        case "cloud.sleet":
            return "sleet"
        case "cloud.hail":
            return "hail"

        // Severe
        case "cloud.bolt", "cloud.bolt.rain":
            return "thunderstorm"

        // Atmosphere
        case "cloud.fog":
            return "fog"
        case "wind", "wind.circle":
            return "wind"

        default:
            return nil
        }
    }

    /// Returnerar en Image med custom väderikon, eller faller tillbaka till SF Symbol.
    @ViewBuilder
    static func icon(for symbolName: String, size: CGFloat = 24) -> some View {
        if let asset = assetName(for: symbolName) {
            Image(asset)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: size, height: size)
        } else {
            Image(systemName: symbolName)
                .font(.system(size: size * 0.7))
                .frame(width: size, height: size)
        }
    }
}
