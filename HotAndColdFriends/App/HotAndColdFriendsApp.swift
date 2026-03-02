import SwiftUI
import FirebaseCore

@main
struct HotAndColdFriendsApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @State private var authManager: AuthManager
    @State private var userService: UserService
    @State private var appWeatherService: AppWeatherService
    @State private var friendService: FriendService

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
    }

    var body: some Scene {
        WindowGroup {
            AppRouter()
                .environment(authManager)
                .environment(userService)
                .environment(appWeatherService)
                .environment(friendService)
        }
    }
}
