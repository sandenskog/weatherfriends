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
                .onOpenURL { url in
                    guard url.scheme == "hotandcold" else { return }

                    if url.host == "invite",
                       let token = url.pathComponents.dropFirst().first {
                        // Handle hotandcold://invite/<token> — invite link redemption
                        Task {
                            guard let uid = authManager.currentUser?.id else { return }
                            try? await inviteService.redeemInvite(
                                token: token,
                                redeemerUid: uid,
                                friendService: friendService,
                                userService: userService
                            )
                        }
                    } else if url.host == "friend",
                              let friendId = url.pathComponents.dropFirst().first {
                        // Handle hotandcold://friend/<id> — widget deep links
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
                    }
                }
        }
    }
}
