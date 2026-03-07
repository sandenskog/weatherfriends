import SwiftUI

// MARK: - Weather Card Renderer

/// Renders a `WeatherCardView` to a `UIImage` using `ImageRenderer`.
///
/// Must be called on the MainActor. Uses the device's screen scale
/// for crisp Retina output.
@MainActor
struct WeatherCardRenderer {

    /// Renders a weather card for the given friend weather data.
    ///
    /// - Parameter friendWeather: The friend's weather data to display.
    /// - Returns: A `UIImage` of the rendered card, or `nil` if rendering fails.
    static func renderCard(friendWeather: FriendWeather) -> UIImage? {
        let view = WeatherCardView(friendWeather: friendWeather)
        let renderer = ImageRenderer(content: view)
        renderer.scale = UIScreen.main.scale
        return renderer.uiImage
    }
}
