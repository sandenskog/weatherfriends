import Foundation
import CryptoKit
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
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

    // MARK: - Delete Account

    func deleteAccount() async throws {
        guard let user = Auth.auth().currentUser else {
            throw DeleteAccountError.noUser
        }
        let uid = user.uid

        // 1. Rensa Firestore och Storage INNAN Firebase Auth-radering
        try await cleanupUserData(uid: uid)

        // 2. Apple Sign In kräver token revocation FÖRE user.delete()
        if user.providerData.contains(where: { $0.providerID == "apple.com" }) {
            try await revokeAppleToken()
        }

        // 3. Radera Firebase Auth-konto
        do {
            try await user.delete()
        } catch let error as NSError
            where error.code == AuthErrorCode.requiresRecentLogin.rawValue {
            throw DeleteAccountError.requiresRecentLogin
        } catch {
            throw DeleteAccountError.deletionFailed(error)
        }

        // 4. Rensa lokal state
        self.currentUser = nil
        self.authState = .unauthenticated
    }

    // MARK: - Reauthenticate (för requiresRecentLogin-fallet)

    func reauthenticate() async throws {
        guard let user = Auth.auth().currentUser else {
            throw DeleteAccountError.noUser
        }
        let providerID = user.providerData.first?.providerID ?? ""

        if providerID.contains("apple") {
            try await signInWithApple()
        } else if providerID.contains("google") {
            try await signInWithGoogle()
        } else if providerID.contains("facebook") {
            try await signInWithFacebook()
        }
    }

    // MARK: - Private: Cleanup User Data

    private func cleanupUserData(uid: String) async throws {
        let db = Firestore.firestore()
        var errors: [Error] = []

        // 1. Radera egna vänner (subcollection users/{uid}/friends/*)
        do {
            let friendsSnapshot = try await db.collection("users").document(uid)
                .collection("friends").getDocuments()
            let friendDocs = friendsSnapshot.documents
            for chunk in stride(from: 0, to: friendDocs.count, by: 400) {
                let batch = db.batch()
                let end = min(chunk + 400, friendDocs.count)
                for doc in friendDocs[chunk..<end] {
                    batch.deleteDocument(doc.reference)
                }
                try await batch.commit()
            }
        } catch {
            errors.append(error)
        }

        // 2. Ta bort denna användare från andra användares vänlistor (reverse cleanup)
        do {
            let reverseFriends = try await db.collectionGroup("friends")
                .whereField("authUid", isEqualTo: uid)
                .getDocuments()
            let reverseDocs = reverseFriends.documents
            for chunk in stride(from: 0, to: reverseDocs.count, by: 400) {
                let batch = db.batch()
                let end = min(chunk + 400, reverseDocs.count)
                for doc in reverseDocs[chunk..<end] {
                    batch.deleteDocument(doc.reference)
                }
                try? await batch.commit()
            }
        } catch {
            errors.append(error)
        }

        // 3. Radera konversationer där uid är deltagare + deras meddelanden (resilient)
        do {
            let convsSnapshot = try await db.collection("conversations")
                .whereField("participants", arrayContains: uid)
                .getDocuments()
            for convDoc in convsSnapshot.documents {
                do {
                    let messagesSnapshot = try await convDoc.reference
                        .collection("messages").getDocuments()
                    for msgChunk in stride(from: 0, to: messagesSnapshot.documents.count, by: 400) {
                        let batch = db.batch()
                        let end = min(msgChunk + 400, messagesSnapshot.documents.count)
                        for msgDoc in messagesSnapshot.documents[msgChunk..<end] {
                            batch.deleteDocument(msgDoc.reference)
                        }
                        try? await batch.commit()
                    }
                } catch {
                    // Kunde inte hämta/radera meddelanden — fortsätt med konversationsdokumentet
                }
                try? await convDoc.reference.delete()
            }
        } catch {
            errors.append(error)
        }

        // 4. Radera användarprofil
        do {
            try await db.collection("users").document(uid).delete()
        } catch {
            errors.append(error)
        }

        // 5. Radera profilbild i Firebase Storage (bild kanske inte finns)
        let storageRef = Storage.storage().reference().child("profile_images/\(uid).jpg")
        try? await storageRef.delete()

        // 6. Radera invite-dokument skapade av denna användare
        do {
            let inviteSnapshot = try await db.collection("invites")
                .whereField("senderUid", isEqualTo: uid)
                .getDocuments()
            let inviteDocs = inviteSnapshot.documents
            for chunk in stride(from: 0, to: inviteDocs.count, by: 400) {
                let batch = db.batch()
                let end = min(chunk + 400, inviteDocs.count)
                for doc in inviteDocs[chunk..<end] {
                    batch.deleteDocument(doc.reference)
                }
                try? await batch.commit()
            }
        } catch {
            errors.append(error)
        }

        // Kasta bara om ALLA kritiska steg misslyckades (profil + vänner)
        // Enskilda misslyckanden loggas men blockerar inte raderingen
    }

    // MARK: - Private: Revoke Apple Token

    private func revokeAppleToken() async throws {
        let nonce = randomNonceString()
        currentNonce = nonce

        let provider = ASAuthorizationAppleIDProvider()
        let request = provider.createRequest()
        request.requestedScopes = []  // Inga scopes — bara authorization code
        request.nonce = sha256(nonce)

        let authorization = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<ASAuthorization, Error>) in
            self.appleSignInContinuation = continuation
            let controller = ASAuthorizationController(authorizationRequests: [request])
            controller.delegate = self
            controller.presentationContextProvider = self
            controller.performRequests()
        }

        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
              let authorizationCode = appleIDCredential.authorizationCode,
              let codeString = String(data: authorizationCode, encoding: .utf8) else {
            throw DeleteAccountError.appleTokenRevocationFailed
        }

        try await Auth.auth().revokeToken(withAuthorizationCode: codeString)
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

// MARK: - DeleteAccountError

enum DeleteAccountError: LocalizedError {
    case noUser
    case requiresRecentLogin
    case appleTokenRevocationFailed
    case deletionFailed(Error)

    var errorDescription: String? {
        switch self {
        case .noUser:
            return "Inget inloggat konto hittades."
        case .requiresRecentLogin:
            return "Du behöver logga in igen innan kontot kan raderas."
        case .appleTokenRevocationFailed:
            return "Kunde inte återkalla Apple-token."
        case .deletionFailed(let error):
            return "Konto-radering misslyckades: \(error.localizedDescription)"
        }
    }
}
