import Foundation

@Observable
@MainActor
class LoginViewModel {
    var isLoading: Bool = false
    var loadingProvider: String? = nil
    var errorMessage: String? = nil

    func signInWithApple(authManager: AuthManager) async {
        await performLogin(provider: "apple", authManager: authManager) {
            try await authManager.signInWithApple()
        }
    }

    func signInWithGoogle(authManager: AuthManager) async {
        await performLogin(provider: "google", authManager: authManager) {
            try await authManager.signInWithGoogle()
        }
    }

    func signInWithFacebook(authManager: AuthManager) async {
        await performLogin(provider: "facebook", authManager: authManager) {
            try await authManager.signInWithFacebook()
        }
    }

    private func performLogin(provider: String, authManager: AuthManager, action: @escaping () async throws -> Void) async {
        isLoading = true
        loadingProvider = provider
        errorMessage = nil

        do {
            try await action()
        } catch let error as AuthError {
            if case .cancelled = error {
                // Avbruten av användaren — visa inget felmeddelande
            } else {
                errorMessage = error.errorDescription ?? "Inloggningen misslyckades. Försök igen."
            }
            authManager.authState = .unauthenticated
        } catch {
            errorMessage = "Inloggningen misslyckades. Försök igen."
            authManager.authState = .unauthenticated
        }

        isLoading = false
        loadingProvider = nil
    }
}
