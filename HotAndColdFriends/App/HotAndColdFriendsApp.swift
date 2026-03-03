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
    @State private var weatherAlertService = WeatherAlertService()

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
    }

    var body: some Scene {
        WindowGroup {
            AppRouter()
                .environment(authManager)
                .environment(userService)
                .environment(appWeatherService)
                .environment(friendService)
                .environment(chatService)
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
