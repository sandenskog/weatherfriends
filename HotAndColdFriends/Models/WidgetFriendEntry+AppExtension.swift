import Foundation

// App-only extension — ej inkluderad i widget-target
// Konverterar FriendWeather (app-modell) till WidgetFriendEntry (delad modell)
extension WidgetFriendEntry {
    static func from(friendWeather fw: FriendWeather) -> WidgetFriendEntry? {
        guard let id = fw.friend.id else { return nil }
        let temp = fw.temperatureCelsius
        // Beräkna RGB-komponenter för temperaturfärg
        let rgb: [Double]
        if let celsius = temp {
            // Samma logik som Color.temperatureColor — hårdkodad för Codable-transport
            if celsius < 0 {
                rgb = [0.6, 0.85, 1.0]   // isblå
            } else if celsius < 10 {
                rgb = [0.4, 0.7, 0.95]   // kylig blå
            } else if celsius < 20 {
                rgb = [0.3, 0.75, 0.45]  // grön
            } else if celsius < 28 {
                rgb = [1.0, 0.65, 0.2]   // orange
            } else {
                rgb = [1.0, 0.3, 0.2]    // röd
            }
        } else {
            rgb = [0.6, 0.6, 0.6]        // grå fallback
        }
        return WidgetFriendEntry(
            id: id,
            displayName: fw.friend.displayName,
            city: fw.friend.city,
            temperatureCelsius: temp,
            symbolName: fw.symbolName,
            temperatureColorRGB: rgb
        )
    }
}
