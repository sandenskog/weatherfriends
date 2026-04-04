import SwiftUI

// MARK: - AvatarView

/// Legacy wrapper around TemperatureRingAvatar.
/// All new code should use TemperatureRingAvatar directly.
struct AvatarView: View {
    let displayName: String
    let temperatureCelsius: Double?
    var size: CGFloat = 44
    var photoURL: String?

    var body: some View {
        TemperatureRingAvatar(
            photoURL: photoURL,
            displayName: displayName,
            temperatureCelsius: temperatureCelsius,
            size: size
        )
    }
}
