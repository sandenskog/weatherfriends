import Foundation
import WeatherKit

struct FriendWeather: Identifiable {
    let friend: Friend
    let weather: CurrentWeather

    var id: String { friend.id ?? UUID().uuidString }

    var temperatureCelsius: Double {
        weather.temperature.converted(to: .celsius).value
    }

    var temperatureFormatted: String {
        weather.temperature.converted(to: .celsius)
            .formatted(.measurement(width: .narrow))
    }

    var symbolName: String { weather.symbolName }
    var conditionDescription: String { weather.condition.description }
    var humidity: Double { weather.humidity * 100 }
    var windSpeed: Double { weather.wind.speed.converted(to: .metersPerSecond).value }
}
