import SwiftUI

struct AppRouter: View {
    @Environment(AuthManager.self) private var authManager

    var body: some View {
        switch authManager.authState {
        case .unauthenticated:
            LoginView()
        case .authenticating:
            ProgressView("Loggar in...")
        case .needsOnboarding:
            OnboardingView()
        case .authenticated:
            FriendListView()
        }
    }
}

#Preview {
    AppRouter()
        .environment(AuthManager())
        .environment(UserService())
}
