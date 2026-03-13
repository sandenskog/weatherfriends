import SwiftUI
import FirebaseCore

@main
struct HotAndColdFriendsApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @State private var authManager: AuthManager
    @State private var userService: UserService
    @State private var appWeatherService: AppWeatherService
    @State private var friendService: FriendService
    @State private var chatService: ChatService
    @State private var weatherAlertService: WeatherAlertService
    @State private var inviteService: InviteService
    @State private var clipboardInviteService: ClipboardInviteService
    @State private var showInviteCelebration = false
    @State private var celebrationZone: TemperatureZone = .warm
    @State private var inviteRedeemName = ""

    init() {
        // Firebase MÅSTE konfigureras innan AuthManager/UserService skapas,
        // eftersom deras init() anropar Auth.auth() och Firestore.firestore()
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }
        _authManager = State(initialValue: AuthManager())
        _userService = State(initialValue: UserService())
        _appWeatherService = State(initialValue: AppWeatherService())
        _friendService = State(initialValue: FriendService())
        _chatService = State(initialValue: ChatService())
        _weatherAlertService = State(initialValue: WeatherAlertService())
        _inviteService = State(initialValue: InviteService())
        _clipboardInviteService = State(initialValue: ClipboardInviteService())
    }

    var body: some Scene {
        WindowGroup {
            AppRouter()
                .preferredColorScheme(.light)
                .environment(authManager)
                .environment(userService)
                .environment(appWeatherService)
                .environment(friendService)
                .environment(chatService)
                .environment(weatherAlertService)
                .environment(inviteService)
                .environment(clipboardInviteService)
                .onOpenURL { url in
                    // Handle Universal Links: https://friendscast.sandenskog.se/invite/<token>
                    if url.host == "friendscast.sandenskog.se",
                       url.pathComponents.count >= 3,
                       url.pathComponents[1] == "invite" {
                        let token = url.pathComponents[2]
                        Task {
                            guard let uid = authManager.currentUser?.id else { return }
                            await redeemInviteWithCelebration(token: token, uid: uid)
                        }
                    }
                    // Handle legacy custom scheme: hotandcold://invite/<token>
                    else if url.scheme == "hotandcold", url.host == "invite",
                       let token = url.pathComponents.dropFirst().first {
                        Task {
                            guard let uid = authManager.currentUser?.id else { return }
                            await redeemInviteWithCelebration(token: String(token), uid: uid)
                        }
                    }
                    // Handle widget deep links: hotandcold://friend/<id>
                    else if url.scheme == "hotandcold", url.host == "friend",
                              let friendId = url.pathComponents.dropFirst().first {
                        NotificationCenter.default.post(
                            name: .openWeatherAlert,
                            object: friendId
                        )
                    }
                }
                .task {
                    delegate.registerForPushNotifications()
                    if let uid = authManager.currentUser?.id {
                        // Track last active for re-engagement push
                        userService.updateLastActive(uid: uid)
                        let friends = (try? await friendService.fetchFriends(uid: uid)) ?? []
                        await weatherAlertService.checkAlertsForFriends(uid: uid, friends: friends)
                        // Check clipboard for deferred deep link invite
                        await clipboardInviteService.checkAndRedeemIfNeeded(
                            authUid: uid,
                            inviteService: inviteService,
                            friendService: friendService,
                            userService: userService
                        )
                        // Trigger celebration if clipboard invite was redeemed
                        if clipboardInviteService.showFriendAddedToast {
                            triggerCelebration(friendName: clipboardInviteService.friendAddedName)
                        }
                    }
                }
                .confettiOverlay(isActive: $showInviteCelebration, zone: celebrationZone)
                .overlay(alignment: .top) {
                    if clipboardInviteService.showFriendAddedToast || !inviteRedeemName.isEmpty {
                        let name = inviteRedeemName.isEmpty
                            ? clipboardInviteService.friendAddedName
                            : inviteRedeemName

                        VStack(spacing: 4) {
                            Text("🎉 New Friend!")
                                .font(.bubbleButton)
                                .foregroundStyle(.white)
                            Text("You are now friends with \(name)")
                                .font(.bubbleCaption)
                                .foregroundStyle(.white.opacity(0.9))
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(
                            LinearGradient(
                                colors: [.bubblePrimary, .bubbleSecondary],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(Capsule())
                        .shadow(color: .bubblePrimary.opacity(0.3), radius: 8, y: 4)
                        .padding(.top, 60)
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                                withAnimation {
                                    clipboardInviteService.showFriendAddedToast = false
                                    inviteRedeemName = ""
                                }
                            }
                        }
                    }
                }
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: clipboardInviteService.showFriendAddedToast)
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: inviteRedeemName)
        }
    }

    // MARK: - Invite Redemption with Celebration

    /// Redeems an invite token and triggers confetti + enhanced toast on success.
    @MainActor
    private func redeemInviteWithCelebration(token: String, uid: String) async {
        do {
            guard let invite = try await inviteService.lookupInviteToken(token) else { return }

            try await inviteService.redeemInvite(
                token: token,
                redeemerUid: uid,
                friendService: friendService,
                userService: userService
            )

            triggerCelebration(friendName: invite.senderDisplayName)
        } catch {
            // Silently fail — error handling in InviteService throws descriptive errors
        }
    }

    /// Triggers confetti animation and shows enhanced friend-added toast.
    @MainActor
    private func triggerCelebration(friendName: String) {
        inviteRedeemName = friendName
        celebrationZone = .warm
        withAnimation {
            showInviteCelebration = true
        }
    }
}
