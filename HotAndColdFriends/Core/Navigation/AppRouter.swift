import SwiftUI

struct AppRouter: View {
    @Environment(AuthManager.self) private var authManager
    @State private var openConversationId: String? = nil

    var body: some View {
        switch authManager.authState {
        case .unauthenticated:
            LoginView()
        case .authenticating:
            ProgressView("Loggar in...")
        case .needsOnboarding:
            OnboardingView()
        case .authenticated:
            MainTabView(openConversationId: $openConversationId)
                .onReceive(NotificationCenter.default.publisher(for: .openChat)) { notification in
                    if let conversationId = notification.object as? String {
                        openConversationId = conversationId
                    }
                }
        }
    }
}

extension Notification.Name {
    static let openChat = Notification.Name("openChat")
}

#Preview {
    AppRouter()
        .environment(AuthManager())
        .environment(UserService())
}
