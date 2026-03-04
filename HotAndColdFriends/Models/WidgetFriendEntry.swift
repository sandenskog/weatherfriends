import Foundation

/// Codable-modell delad mellan app och widget via App Group UserDefaults.
/// Innehåller all data widgeten behöver — inga nätverksanrop i widget-extension.
struct WidgetFriendEntry: Codable {
    let id: String
    let displayName: String
    let city: String
    let temperatureCelsius: Double?
    let symbolName: String
    let temperatureColorRGB: [Double]  // [r, g, b] 0...1 — från Color.temperatureColor
}
