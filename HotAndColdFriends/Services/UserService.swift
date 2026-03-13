import Foundation
import FirebaseFirestore
import FirebaseStorage

@Observable
@MainActor
class UserService {
    private let db = Firestore.firestore()
    private let storage = Storage.storage()

    // MARK: - Firestore CRUD

    /// Skapar eller uppdaterar en användarprofil i Firestore
    /// Använder merge: true för att inte skriva över befintliga fält vid uppdatering
    func createUserProfile(_ user: AppUser) async throws {
        guard let id = user.id else {
            throw UserServiceError.missingUserID
        }
        try await db.collection("users").document(id).setData(from: user, merge: true)
    }

    /// Hämtar en användarprofil från Firestore
    /// Returnerar nil om profilen inte finns
    func fetchUser(uid: String) async throws -> AppUser? {
        let document = try await db.collection("users").document(uid).getDocument()
        guard document.exists else { return nil }
        return try document.data(as: AppUser.self)
    }

    /// Uppdaterar specifika fält på en användarprofil
    func updateUser(uid: String, data: [String: Any]) async throws {
        try await db.collection("users").document(uid).updateData(data)
    }

    // MARK: - Activity Tracking

    /// Updates lastActiveAt timestamp on the user document.
    /// Called on each app launch to track engagement for re-engagement push.
    /// Fire-and-forget — errors are silently ignored.
    func updateLastActive(uid: String) {
        Task {
            try? await db.collection("users").document(uid).updateData([
                "lastActiveAt": FieldValue.serverTimestamp()
            ])
        }
    }

    // MARK: - Auth UID Lookup

    // DEPRECATED — used only by ContactImportService and OnboardingViewModel for bulk import.
    // New friend connections should use InviteService (invite-link flow) instead.
    /// Slår upp Firebase Auth UID för en användare via displayName
    /// Returnerar nil vid nätverksfel, timeout, eller ingen match
    func lookupAuthUid(byDisplayName displayName: String) async -> String? {
        let snapshot = try? await db
            .collection("users")
            .whereField("displayName", isEqualTo: displayName)
            .limit(to: 1)
            .getDocuments()
        return snapshot?.documents.first?.documentID
    }

    // MARK: - Firebase Storage

    /// Laddar upp en profilbild till Firebase Storage
    /// Returnerar download URL-strängen
    func uploadProfileImage(uid: String, imageData: Data) async throws -> String {
        let ref = storage.reference().child("profile_images/\(uid).jpg")
        let _ = try await ref.putDataAsync(imageData)
        let downloadURL = try await ref.downloadURL()
        return downloadURL.absoluteString
    }
}

// MARK: - Errors

enum UserServiceError: LocalizedError {
    case missingUserID

    var errorDescription: String? {
        switch self {
        case .missingUserID:
            return "Användar-ID saknas — kan inte spara profilen"
        }
    }
}
