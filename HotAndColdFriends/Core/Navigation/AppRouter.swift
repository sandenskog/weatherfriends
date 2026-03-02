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
            MainTabView()
        }
    }
}

// MARK: - Temporär MainTabView (ersätts i fas 2)

struct MainTabView: View {
    @Environment(AuthManager.self) private var authManager
    @State private var showProfile = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Image(systemName: "cloud.sun.fill")
                    .font(.system(size: 72))
                    .foregroundStyle(.secondary)

                Text("Välkommen!")
                    .font(.title2)
                    .fontWeight(.semibold)

                if let name = authManager.currentUser?.displayName, !name.isEmpty {
                    Text("Hej, \(name)!")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }

                Divider()
                    .padding(.horizontal)

                VStack(spacing: 12) {
                    Button {
                        showProfile = true
                    } label: {
                        Label("Visa min profil", systemImage: "person.circle")
                            .font(.body.weight(.medium))
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    Button(role: .destructive) {
                        authManager.signOut()
                    } label: {
                        Label("Logga ut", systemImage: "rectangle.portrait.and.arrow.right")
                            .font(.body.weight(.medium))
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                .padding(.horizontal)
            }
            .navigationTitle("Hot & Cold Friends")
            .navigationBarTitleDisplayMode(.inline)
        }
        .sheet(isPresented: $showProfile) {
            if let uid = authManager.currentUser?.id {
                ProfileView(uid: uid)
            }
        }
    }
}

#Preview {
    AppRouter()
        .environment(AuthManager())
        .environment(UserService())
}
