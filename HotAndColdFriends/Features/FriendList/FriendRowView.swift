import SwiftUI

// MARK: - FriendRowView

struct FriendRowView: View {
    let friendWeather: FriendWeather

    @State private var isPressed = false

    // MARK: - Derived

    private var zone: TemperatureZone {
        TemperatureZone(celsius: friendWeather.temperatureCelsius ?? -99)
    }

    // MARK: - Body

    var body: some View {
        HStack(spacing: Spacing.md) {
            AvatarView(
                displayName: friendWeather.friend.displayName,
                temperatureCelsius: friendWeather.temperatureCelsius,
                size: 52,
                photoURL: friendWeather.friend.photoURL
            )

            VStack(alignment: .leading, spacing: 2) {
                Text(friendWeather.friend.displayName)
                    .font(.bubbleH3)
                    .foregroundStyle(Color.bubbleTextPrimary)
                    .lineLimit(1)

                Text(friendWeather.friend.city)
                    .font(.bubbleCaption)
                    .foregroundStyle(Color.bubbleTextSecondary)
                    .lineLimit(1)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(friendWeather.temperatureFormatted)
                    .font(.bubbleTemperature)
                    .foregroundStyle(zone.color)

                WeatherIconMapper.icon(for: friendWeather.symbolName, size: 28)
                    .foregroundStyle(zone.color)
            }
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm + Spacing.xs)
        .background(Color.bubbleSurface)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md))
        .modifier(CardShadowModifier(isPressed: isPressed))
        .scaleEffect(isPressed ? 1.02 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
        .onLongPressGesture(minimumDuration: 0, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
    }
}

// MARK: - CardShadowModifier

/// Switches between shadowMd and shadowLg depending on press state.
private struct CardShadowModifier: ViewModifier {
    let isPressed: Bool

    func body(content: Content) -> some View {
        if isPressed {
            content.shadowLg()
        } else {
            content.shadowMd()
        }
    }
}
