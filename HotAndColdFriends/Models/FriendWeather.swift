import Foundation
import WeatherKit

struct FriendWeather: Identifiable {
    let friend: Friend
    let weather: CurrentWeather?

    var id: String { friend.id ?? UUID().uuidString }

    var temperatureCelsius: Double? {
        weather?.temperature.converted(to: .celsius).value
    }

    var temperatureFormatted: String {
        guard let weather else { return "—" }
        let celsius = weather.temperature.converted(to: .celsius).value
        return String(format: "%.0f°", celsius)
    }

    var symbolName: String { weather?.symbolName ?? "questionmark.circle" }
    var conditionDescription: String { weather?.condition.description ?? "Väder ej tillgängligt" }
    var humidity: Double? { weather.map { $0.humidity * 100 } }
    var windSpeed: Double? { weather.map { $0.wind.speed.converted(to: .metersPerSecond).value } }
}
