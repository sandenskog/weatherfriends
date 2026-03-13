import SwiftUI

// MARK: - Card Mode

/// Which card type is being previewed.
private enum CardMode {
    case single
    case comparison
}

// MARK: - Weather Card Preview Sheet

/// A bottom-sheet that previews a shareable weather card and offers
/// sharing via the system share sheet (with invite link) or
/// directly to Instagram Stories.
///
/// Supports switching between single friend card and comparison card
/// when the user's own weather is available.
struct WeatherCardPreviewSheet: View {

    let friendWeather: FriendWeather
    var myWeather: FriendWeather? = nil

    @Environment(InviteService.self) private var inviteService
    @Environment(UserService.self) private var userService
    @Environment(AuthManager.self) private var authManager
    @Environment(\.dismiss) private var dismiss

    @State private var renderedImage: UIImage?
    @State private var shareText: String = ""
    @State private var cardMode: CardMode = .single
    @State private var shareHapticTrigger = false

    // MARK: - Body

    var body: some View {
        VStack(spacing: 16) {
            dragIndicator

            if myWeather != nil {
                cardModePicker
            }

            cardPreview

            Spacer()

            shareButtons

            Spacer()
                .frame(height: 8)
        }
        .padding()
        .sensoryFeedback(.impact(weight: .light), trigger: shareHapticTrigger)
        .task {
            await prepareShareContent()
        }
        .onChange(of: cardMode) { _, _ in
            Task { await prepareShareContent() }
        }
    }

    // MARK: - Drag Indicator

    private var dragIndicator: some View {
        Capsule()
            .fill(Color.secondary.opacity(0.4))
            .frame(width: 40, height: 5)
            .padding(.top, 8)
    }

    // MARK: - Card Mode Picker

    private var cardModePicker: some View {
        HStack(spacing: 0) {
            modeButton(title: "Card", mode: .single)
            modeButton(title: "Compare", mode: .comparison)
        }
        .background(Color.secondary.opacity(0.12))
        .clipShape(Capsule())
    }

    private func modeButton(title: String, mode: CardMode) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                cardMode = mode
            }
        } label: {
            Text(title)
                .font(.bubbleButton)
                .foregroundStyle(cardMode == mode ? .white : .secondary)
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.sm)
                .background {
                    if cardMode == mode {
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [.bubblePrimary, .bubbleSecondary],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    }
                }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Card Preview

    @ViewBuilder
    private var cardPreview: some View {
        switch cardMode {
        case .single:
            WeatherCardView(friendWeather: friendWeather)
                .scaleEffect(0.65)
                .frame(
                    width: 390 * 0.65,
                    height: 693 * 0.65
                )
                .clipShape(RoundedRectangle(cornerRadius: 24))
                .shadow(color: .black.opacity(0.2), radius: 12, y: 6)

        case .comparison:
            if let myWeather {
                ComparisonCardView(userWeather: myWeather, friendWeather: friendWeather)
                    .scaleEffect(0.65)
                    .frame(
                        width: 390 * 0.65,
                        height: 693 * 0.65
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 24))
                    .shadow(color: .black.opacity(0.2), radius: 12, y: 6)
            }
        }
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
                        shareHapticTrigger.toggle()
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
        switch cardMode {
        case .single:
            renderedImage = WeatherCardRenderer.renderCard(friendWeather: friendWeather)
        case .comparison:
            if let myWeather {
                renderedImage = WeatherCardRenderer.renderComparison(user: myWeather, friend: friendWeather)
            }
        }

        guard let uid = authManager.currentUser?.id else { return }
        if let token = try? await inviteService.getOrCreateInviteToken(for: uid, userService: userService) {
            let url = inviteService.inviteURL(token: token)
            shareText = "It's \(friendWeather.temperatureFormatted) and \(friendWeather.conditionDescription.lowercased()) in \(friendWeather.friend.city) \(url.absoluteString)"
        } else {
            shareText = "It's \(friendWeather.temperatureFormatted) and \(friendWeather.conditionDescription.lowercased()) in \(friendWeather.friend.city)"
        }
    }
}
