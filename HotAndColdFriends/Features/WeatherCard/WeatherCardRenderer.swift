import SwiftUI

// MARK: - Weather Card Renderer

/// Renders weather card views to `UIImage` using `ImageRenderer`.
///
/// Must be called on the MainActor. Uses the device's screen scale
/// for crisp Retina output.
@MainActor
struct WeatherCardRenderer {

    /// Renders a single-friend weather card.
    ///
    /// - Parameter friendWeather: The friend's weather data to display.
    /// - Returns: A `UIImage` of the rendered card, or `nil` if rendering fails.
    static func renderCard(friendWeather: FriendWeather) -> UIImage? {
        let view = WeatherCardView(friendWeather: friendWeather)
        let renderer = ImageRenderer(content: view)
        renderer.scale = UIScreen.main.scale
        return renderer.uiImage
    }

    /// Renders a "Me vs You" comparison card with two friends side-by-side.
    ///
    /// - Parameters:
    ///   - user: The current user's weather data.
    ///   - friend: The friend's weather data.
    /// - Returns: A `UIImage` of the rendered comparison card, or `nil` if rendering fails.
    static func renderComparison(user: FriendWeather, friend: FriendWeather) -> UIImage? {
        let view = ComparisonCardView(userWeather: user, friendWeather: friend)
        let renderer = ImageRenderer(content: view)
        renderer.scale = UIScreen.main.scale
        return renderer.uiImage
    }

    /// Renders a daily digest card showing all friends' weather.
    ///
    /// - Parameter friends: All friends' weather data to include.
    /// - Returns: A `UIImage` of the rendered digest card, or `nil` if rendering fails.
    static func renderDigest(friends: [FriendWeather]) -> UIImage? {
        let view = DailyDigestCardView(friends: friends)
        let renderer = ImageRenderer(content: view)
        renderer.scale = UIScreen.main.scale
        return renderer.uiImage
    }
}
