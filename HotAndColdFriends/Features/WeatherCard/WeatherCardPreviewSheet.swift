import SwiftUI

// MARK: - Weather Card Preview Sheet

/// A bottom-sheet that previews a shareable weather card and offers
/// sharing via the system share sheet (with invite link) or
/// directly to Instagram Stories.
struct WeatherCardPreviewSheet: View {

    let friendWeather: FriendWeather

    @Environment(InviteService.self) private var inviteService
    @Environment(UserService.self) private var userService
    @Environment(AuthManager.self) private var authManager
    @Environment(\.dismiss) private var dismiss

    @State private var renderedImage: UIImage?
    @State private var shareText: String = ""

    // MARK: - Body

    var body: some View {
        VStack(spacing: 16) {
            dragIndicator

            cardPreview

            Spacer()

            shareButtons

            Spacer()
                .frame(height: 8)
        }
        .padding()
        .task {
            await prepareShareContent()
        }
    }

    // MARK: - Drag Indicator

    private var dragIndicator: some View {
        Capsule()
            .fill(Color.secondary.opacity(0.4))
            .frame(width: 40, height: 5)
            .padding(.top, 8)
    }

    // MARK: - Card Preview

    private var cardPreview: some View {
        WeatherCardView(friendWeather: friendWeather)
            .scaleEffect(0.65)
            .frame(
                width: 390 * 0.65,
                height: 693 * 0.65
            )
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .shadow(color: .black.opacity(0.2), radius: 12, y: 6)
    }

    // MARK: - Share Buttons

    private var shareButtons: some View {
        HStack(spacing: 16) {
            if let image = renderedImage {
                let photo = Image(uiImage: image)

                ShareLink(
                    item: photo,
                    message: Text(shareText),
                    preview: SharePreview(
                        friendWeather.friend.displayName,
                        image: photo
                    )
                ) {
                    Label("Share", systemImage: "square.and.arrow.up")
                        .font(.bubbleButton)
                        .foregroundStyle(.white)
                        .padding(.horizontal, Spacing.lg)
                        .padding(.vertical, Spacing.sm + Spacing.xs)
                        .background(
                            LinearGradient(
                                colors: [.bubblePrimary, .bubbleSecondary],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(Capsule())
                }

                if InstagramStoriesService.canShareToStories {
                    Button {
                        InstagramStoriesService.shareToStories(image: image)
                    } label: {
                        Label("Instagram", systemImage: "camera")
                            .font(.bubbleButton)
                            .foregroundStyle(.white)
                            .padding(.horizontal, Spacing.lg)
                            .padding(.vertical, Spacing.sm + Spacing.xs)
                            .background(
                                LinearGradient(
                                    colors: [
                                        Color(red: 0.51, green: 0.23, blue: 0.72),
                                        Color(red: 0.89, green: 0.22, blue: 0.36),
                                        Color(red: 0.99, green: 0.69, blue: 0.27)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .clipShape(Capsule())
                    }
                }
            } else {
                ProgressView()
                    .frame(height: 44)
            }
        }
    }

    // MARK: - Prepare Share Content

    private func prepareShareContent() async {
        renderedImage = WeatherCardRenderer.renderCard(friendWeather: friendWeather)

        guard let uid = authManager.currentUser?.id else { return }
        if let token = try? await inviteService.getOrCreateInviteToken(for: uid, userService: userService) {
            let url = inviteService.inviteURL(token: token)
            shareText = "It's \(friendWeather.temperatureFormatted) and \(friendWeather.conditionDescription.lowercased()) in \(friendWeather.friend.city) \(url.absoluteString)"
        } else {
            shareText = "It's \(friendWeather.temperatureFormatted) and \(friendWeather.conditionDescription.lowercased()) in \(friendWeather.friend.city)"
        }
    }
}
