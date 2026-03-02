import Foundation
import FirebaseAuth

@Observable
@MainActor
class AuthManager {
    var currentUser: AppUser?
    var authState: AuthState = .unauthenticated

    // nonisolated(unsafe) tillåter åtkomst från deinit (nonisolated context)
    nonisolated(unsafe) private var listenerHandle: AuthStateDidChangeListenerHandle?

    init() {
        listenerHandle = Auth.auth().addStateDidChangeListener { [weak self] _, firebaseUser in
            Task { @MainActor in
                if let firebaseUser = firebaseUser {
                    self?.authState = .authenticating
                    await self?.fetchOrCreateUserProfile(uid: firebaseUser.uid)
                } else {
                    self?.authState = .unauthenticated
                    self?.currentUser = nil
                }
            }
        }
    }

    deinit {
        if let handle = listenerHandle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }

    // MARK: - User Profile

    private func fetchOrCreateUserProfile(uid: String) async {
        let userService = UserService()
        do {
            if let user = try await userService.fetchUser(uid: uid) {
                self.currentUser = user
                // Om displayName saknas behöver användaren onboarding
                if user.displayName.isEmpty {
                    self.authState = .needsOnboarding
                } else {
                    self.authState = .authenticated
                }
            } else {
                // Ny användare — behöver onboarding
                self.authState = .needsOnboarding
            }
        } catch {
            // Vid fel — sätt som unauthenticated för säkerhetens skull
            self.authState = .unauthenticated
            self.currentUser = nil
        }
    }

    // MARK: - Sign Out

    func signOut() {
        do {
            try Auth.auth().signOut()
            self.currentUser = nil
            self.authState = .unauthenticated
        } catch {
            // Log error — state listener kommer att reagera
        }
    }

    // MARK: - Login Methods (implementeras i Plan 02)

    func signInWithApple() async throws {
        // TODO: Implementeras i Plan 02 — Apple Sign-In med nonce-flöde
    }

    func signInWithGoogle() async throws {
        // TODO: Implementeras i Plan 02 — Google Sign-In via GIDSignIn
    }

    func signInWithFacebook() async throws {
        // TODO: Implementeras i Plan 02 — Facebook Login via FBSDKLoginManager
    }
}
