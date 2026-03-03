import SwiftUI

struct AppRouter: View {
    @Environment(AuthManager.self) private var authManager
    @State private var openConversationId: String? = nil
    @State private var openWeatherAlertFriendId: String? = nil

    var body: some View {
        switch authManager.authState {
        case .unauthenticated:
            LoginView()
        case .authenticating:
            ProgressView("Loggar in...")
        case .needsOnboarding:
            OnboardingView()
        case .authenticated:
            MainTabView(
                openConversationId: $openConversationId,
                openWeatherAlertFriendId: $openWeatherAlertFriendId
            )
            .onReceive(NotificationCenter.default.publisher(for: .openChat)) { notification in
                if let conversationId = notification.object as? String {
                    openConversationId = conversationId
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .openWeatherAlert)) { notification in
                if let friendId = notification.object as? String {
                    openWeatherAlertFriendId = friendId
                }
            }
        }
    }
}

extension Notification.Name {
    static let openChat = Notification.Name("openChat")
    static let openWeatherAlert = Notification.Name("openWeatherAlert")
}

#Preview {
    AppRouter()
        .environment(AuthManager())
        .environment(UserService())
}
