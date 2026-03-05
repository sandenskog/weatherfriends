import SwiftUI

// MARK: - AvatarView

/// Universal gradient avatar component.
///
/// Displays a circle filled with the temperature-zone gradient and white initials.
/// If a valid `photoURL` is provided and the image loads successfully, the photo
/// is shown instead of the gradient + initials.
///
/// Reusable across FriendRowView, profile screens and chat headers.
struct AvatarView: View {

    // MARK: - Properties

    let displayName: String
    let temperatureCelsius: Double?
    var size: CGFloat = 52
    var photoURL: String? = nil

    // MARK: - Derived

    private var zone: TemperatureZone {
        guard let celsius = temperatureCelsius else { return .arctic }
        return TemperatureZone(celsius: celsius)
    }

    private var initials: String {
        displayName
            .split(separator: " ")
            .prefix(2)
            .compactMap { $0.first.map(String.init) }
            .joined()
            .uppercased()
    }

    // MARK: - Body

    var body: some View {
        if let urlString = photoURL, let url = URL(string: urlString) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(width: size, height: size)
                        .clipShape(Circle())
                default:
                    gradientCircle
                }
            }
            .frame(width: size, height: size)
        } else {
            gradientCircle
        }
    }

    // MARK: - Sub-views

    private var gradientCircle: some View {
        ZStack {
            Circle()
                .fill(zone.gradient)

            Text(initials)
                .font(.system(size: size * 0.38, weight: .bold))
                .foregroundStyle(.white)
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: Spacing.lg) {
        // All 5 zones at three different sizes
        ForEach([40.0, 52.0, 64.0], id: \.self) { size in
            HStack(spacing: Spacing.md) {
                AvatarView(displayName: "Ana Bergström",   temperatureCelsius: 32,   size: size)
                AvatarView(displayName: "Bo Carlsson",     temperatureCelsius: 24,   size: size)
                AvatarView(displayName: "Celine Dupont",   temperatureCelsius: 15,   size: size)
                AvatarView(displayName: "David Kim",       temperatureCelsius: 5,    size: size)
                AvatarView(displayName: "Ella Magnusson",  temperatureCelsius: -10,  size: size)
            }
        }

        // Nil temperature → arctic fallback
        AvatarView(displayName: "Unknown User", temperatureCelsius: nil, size: 52)

        // Single-word name → one initial
        AvatarView(displayName: "Madonna", temperatureCelsius: 28, size: 52)
    }
    .padding(Spacing.lg)
    .background(Color(hex: 0xF4F6FB))
}
