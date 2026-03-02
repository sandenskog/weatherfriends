import Foundation
import CryptoKit
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore
import GoogleSignIn
import FacebookLogin
import AuthenticationServices
import UIKit

@Observable
@MainActor
class AuthManager: NSObject {
    var currentUser: AppUser?
    var authState: AuthState = .unauthenticated

    // nonisolated(unsafe) tillåter åtkomst från deinit (nonisolated context)
    nonisolated(unsafe) private var listenerHandle: AuthStateDidChangeListenerHandle?

    // Nonce för Apple Sign-In — måste bevaras mellan request och callback
    nonisolated(unsafe) private var currentNonce: String?

    // Continuation för Apple Sign-In async/await-brygga
    private var appleSignInContinuation: CheckedContinuation<ASAuthorization, Error>?

    override init() {
        super.init()
        listenerHandle = Auth.auth().addStateDidChangeListener { [weak self] _, firebaseUser in
            Task { @MainActor in
                if let firebaseUser = firebaseUser {
                    self?.authState = .authenticating
                    await self?.fetchOrCreateUserProfile(firebaseUser: firebaseUser)
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

    private func fetchOrCreateUserProfile(firebaseUser: User) async {
        let userService = UserService()
        do {
            if let user = try await userService.fetchUser(uid: firebaseUser.uid) {
                var updatedUser = user
                // Apple skickar displayName bara vid FÖRSTA inloggning.
                // Om Firestore-profilen saknar displayName men Firebase Auth-user har ett, spara det.
                if updatedUser.displayName.isEmpty, let authDisplayName = firebaseUser.displayName, !authDisplayName.isEmpty {
                    updatedUser.displayName = authDisplayName
                    try? await userService.updateUser(uid: firebaseUser.uid, data: ["displayName": authDisplayName])
                }
                self.currentUser = updatedUser
                if updatedUser.displayName.isEmpty {
                    self.authState = .needsOnboarding
                } else {
                    self.authState = .authenticated
                }
            } else {
                // Ny användare — skapa profil om vi har namn (Apple first-time login)
                let newUser = AppUser(
                    displayName: firebaseUser.displayName ?? "",
                    photoURL: firebaseUser.photoURL?.absoluteString,
                    city: "",
                    authProvider: providerID(from: firebaseUser)
                )
                // Sätt id manuellt så createUserProfile kan skriva till rätt dokument
                // AppUser.id är @DocumentID — vi mappar uid via en workaround
                // UserService.createUserProfile kräver user.id — vi skriver direkt till Firestore
                let db = Firestore.firestore()
                try? db.collection("users").document(firebaseUser.uid).setData(from: newUser, merge: true)
                self.authState = .needsOnboarding
            }
        } catch {
            self.authState = .unauthenticated
            self.currentUser = nil
        }
    }

    private func providerID(from user: User) -> String {
        let provider = user.providerData.first?.providerID ?? ""
        if provider.contains("apple") { return "apple" }
        if provider.contains("google") { return "google" }
        if provider.contains("facebook") { return "facebook" }
        return provider
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

    // MARK: - Sign In With Apple

    func signInWithApple() async throws {
        authState = .authenticating

        let nonce = randomNonceString()
        currentNonce = nonce

        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)

        let authorization = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<ASAuthorization, Error>) in
            self.appleSignInContinuation = continuation
            let authController = ASAuthorizationController(authorizationRequests: [request])
            authController.delegate = self
            authController.presentationContextProvider = self
            authController.performRequests()
        }

        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
              let idTokenData = appleIDCredential.identityToken,
              let idTokenString = String(data: idTokenData, encoding: .utf8),
              let rawNonce = currentNonce else {
            authState = .unauthenticated
            throw AuthError.invalidCredential
        }

        // Hämta displayName från Apple (skickas bara vid FÖRSTA inloggning)
        var displayName: String? = nil
        if let fullName = appleIDCredential.fullName {
            let components = [fullName.givenName, fullName.familyName].compactMap { $0 }
            if !components.isEmpty {
                displayName = components.joined(separator: " ")
            }
        }

        // Skapa Firebase credential med RAW nonce (ej hash)
        let credential = OAuthProvider.appleCredential(
            withIDToken: idTokenString,
            rawNonce: rawNonce,
            fullName: appleIDCredential.fullName
        )

        let result = try await Auth.auth().signIn(with: credential)

        // Apple-namn sparas manuellt i Firebase Auth user vid första inloggning
        if let displayName = displayName, !displayName.isEmpty {
            let changeRequest = result.user.createProfileChangeRequest()
            changeRequest.displayName = displayName
            try? await changeRequest.commitChanges()
        }
    }

    // MARK: - Sign In With Google

    func signInWithGoogle() async throws {
        authState = .authenticating

        guard let clientID = FirebaseApp.app()?.options.clientID else {
            authState = .unauthenticated
            throw AuthError.missingClientID
        }

        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config

        guard let rootViewController = rootViewController() else {
            authState = .unauthenticated
            throw AuthError.noRootViewController
        }

        let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController)

        guard let idToken = result.user.idToken?.tokenString else {
            authState = .unauthenticated
            throw AuthError.invalidCredential
        }

        let credential = GoogleAuthProvider.credential(
            withIDToken: idToken,
            accessToken: result.user.accessToken.tokenString
        )

        try await Auth.auth().signIn(with: credential)
    }

    // MARK: - Sign In With Facebook

    func signInWithFacebook() async throws {
        authState = .authenticating

        guard let rootViewController = rootViewController() else {
            authState = .unauthenticated
            throw AuthError.noRootViewController
        }

        let loginManager = LoginManager()
        let loginResult = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<LoginManagerLoginResult, Error>) in
            loginManager.logIn(permissions: ["email", "public_profile"], from: rootViewController) { result, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                guard let result = result else {
                    continuation.resume(throwing: AuthError.invalidCredential)
                    return
                }
                continuation.resume(returning: result)
            }
        }

        if loginResult.isCancelled {
            authState = .unauthenticated
            throw AuthError.cancelled
        }

        guard let tokenString = loginResult.token?.tokenString else {
            authState = .unauthenticated
            throw AuthError.invalidCredential
        }

        let credential = FacebookAuthProvider.credential(withAccessToken: tokenString)
        try await Auth.auth().signIn(with: credential)
    }

    // MARK: - Helpers

    @MainActor
    private func rootViewController() -> UIViewController? {
        return UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }?
            .rootViewController
    }

    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        var randomBytes = [UInt8](repeating: 0, count: length)
        let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        if errorCode != errSecSuccess {
            fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
        }
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        let nonce = randomBytes.map { byte in
            charset[Int(byte) % charset.count]
        }
        return String(nonce)
    }

    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        return hashedData.compactMap { String(format: "%02x", $0) }.joined()
    }
}

// MARK: - ASAuthorizationControllerDelegate

extension AuthManager: ASAuthorizationControllerDelegate {
    nonisolated func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        Task { @MainActor in
            self.appleSignInContinuation?.resume(returning: authorization)
            self.appleSignInContinuation = nil
        }
    }

    nonisolated func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        Task { @MainActor in
            self.appleSignInContinuation?.resume(throwing: error)
            self.appleSignInContinuation = nil
            self.authState = .unauthenticated
        }
    }
}

// MARK: - ASAuthorizationControllerPresentationContextProviding

extension AuthManager: ASAuthorizationControllerPresentationContextProviding {
    nonisolated func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        // Körs på nonisolated context — använd DispatchQueue.main.sync för att hämta window
        return DispatchQueue.main.sync {
            UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .flatMap { $0.windows }
                .first { $0.isKeyWindow } ?? UIWindow()
        }
    }
}

// MARK: - AuthError

enum AuthError: LocalizedError {
    case invalidCredential
    case missingClientID
    case noRootViewController
    case cancelled

    var errorDescription: String? {
        switch self {
        case .invalidCredential:
            return "Inloggningen misslyckades. Ogiltig credential."
        case .missingClientID:
            return "Firebase-konfiguration saknas. Kontrollera GoogleService-Info.plist."
        case .noRootViewController:
            return "Kunde inte presentera inloggningsdialog."
        case .cancelled:
            return "Inloggningen avbröts."
        }
    }
}
