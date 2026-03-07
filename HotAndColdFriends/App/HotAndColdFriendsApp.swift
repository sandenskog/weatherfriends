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
                .environment(authManager)
                .environment(userService)
                .environment(appWeatherService)
                .environment(friendService)
                .environment(chatService)
                .environment(weatherAlertService)
                .environment(inviteService)
                .environment(clipboardInviteService)
                .onOpenURL { url in
                    // Handle Universal Links: https://apps.sandenskog.se/invite/<token>
                    if url.host == "apps.sandenskog.se",
                       url.pathComponents.count >= 3,
                       url.pathComponents[1] == "invite" {
                        let token = url.pathComponents[2]
                        Task {
                            guard let uid = authManager.currentUser?.id else { return }
                            try? await inviteService.redeemInvite(
                                token: token,
                                redeemerUid: uid,
                                friendService: friendService,
                                userService: userService
                            )
                        }
                    }
                    // Handle legacy custom scheme: hotandcold://invite/<token>
                    else if url.scheme == "hotandcold", url.host == "invite",
                       let token = url.pathComponents.dropFirst().first {
                        Task {
                            guard let uid = authManager.currentUser?.id else { return }
                            try? await inviteService.redeemInvite(
                                token: token,
                                redeemerUid: uid,
                                friendService: friendService,
                                userService: userService
                            )
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
                    // Kontrollera extremvader for vanners platser
                    if let uid = authManager.currentUser?.id {
                        let friends = (try? await friendService.fetchFriends(uid: uid)) ?? []
                        await weatherAlertService.checkAlertsForFriends(uid: uid, friends: friends)
                        // Check clipboard for deferred deep link invite
                        await clipboardInviteService.checkAndRedeemIfNeeded(
                            authUid: uid,
                            inviteService: inviteService,
                            friendService: friendService,
                            userService: userService
                        )
                    }
                }
                .overlay(alignment: .top) {
                    if clipboardInviteService.showFriendAddedToast {
                        Text("You are now friends with \(clipboardInviteService.friendAddedName)!")
                            .font(.subheadline.weight(.medium))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(.ultraThinMaterial)
                            .clipShape(Capsule())
                            .shadow(radius: 4)
                            .padding(.top, 60)
                            .transition(.move(edge: .top).combined(with: .opacity))
                            .onAppear {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                    withAnimation {
                                        clipboardInviteService.showFriendAddedToast = false
                                    }
                                }
                            }
                    }
                }
                .animation(.easeInOut, value: clipboardInviteService.showFriendAddedToast)
        }
    }
}
