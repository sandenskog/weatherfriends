import SwiftUI

struct AppRouter: View {
    @Environment(AuthManager.self) private var authManager

    var body: some View {
        switch authManager.authState {
        case .unauthenticated:
            LoginView() // Placeholder — implementeras i Plan 02
        case .authenticating:
            ProgressView("Loggar in...")
        case .needsOnboarding:
            Text("Onboarding") // Placeholder — implementeras i Plan 03
                .font(.headline)
        case .authenticated:
            Text("Huvudvy") // Placeholder — implementeras i fas 2
                .font(.headline)
        }
    }
}

#Preview {
    AppRouter()
        .environment(AuthManager())
}
