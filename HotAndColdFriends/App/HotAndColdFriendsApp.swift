import SwiftUI
import FirebaseCore

@main
struct HotAndColdFriendsApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @State private var authManager = AuthManager()
    @State private var userService = UserService()

    var body: some Scene {
        WindowGroup {
            AppRouter()
                .environment(authManager)
                .environment(userService)
        }
    }
}
