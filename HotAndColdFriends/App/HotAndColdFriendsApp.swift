import SwiftUI
import FirebaseCore

@main
struct HotAndColdFriendsApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @State private var authManager = AuthManager()

    var body: some Scene {
        WindowGroup {
            AppRouter()
                .environment(authManager)
        }
    }
}
