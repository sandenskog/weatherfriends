import Foundation
import FirebaseFirestore
import Observation

enum FriendServiceError: LocalizedError {
    case maxFavoritesReached
    case missingFriendID

    var errorDescription: String? {
        switch self {
        case .maxFavoritesReached:
            return "Du har redan 6 favoriter. Ta bort en för att lägga till en ny."
        case .missingFriendID:
            return "Vän-ID saknas."
        }
    }
}

@Observable
@MainActor
class FriendService {
    private let db = Firestore.firestore()

    // MARK: - Fetch

    func fetchFriends(uid: String) async throws -> [Friend] {
        let snapshot = try await db
            .collection("users")
            .document(uid)
            .collection("friends")
            .getDocuments()
        return snapshot.documents
            .compactMap { doc in
                do {
                    return try doc.data(as: Friend.self)
                } catch {
                    print("⚠️ FriendService: Failed to decode friend \(doc.documentID): \(error)")
                    print("⚠️ FriendService: Raw data: \(doc.data())")
                    return nil
                }
            }
            .sorted { $0.displayName < $1.displayName }
    }

    // MARK: - Add

    func addFriend(uid: String, friend: Friend) async throws {
        if friend.isFavorite {
            let count = try await favoritesCount(uid: uid)
            if count >= 6 {
                throw FriendServiceError.maxFavoritesReached
            }
        }
        try db
            .collection("users")
            .document(uid)
            .collection("friends")
            .addDocument(from: friend)
    }

    // MARK: - Update

    func updateFriend(uid: String, friendId: String, data: [String: Any]) async throws {
        try await db
            .collection("users")
            .document(uid)
            .collection("friends")
            .document(friendId)
            .updateData(data)
    }

    // MARK: - Remove

    func removeFriend(uid: String, friendId: String) async throws {
        try await db
            .collection("users")
            .document(uid)
            .collection("friends")
            .document(friendId)
            .delete()
    }

    // MARK: - Toggle Favorite

    func toggleFavorite(uid: String, friend: Friend) async throws {
        guard let friendId = friend.id else {
            throw FriendServiceError.missingFriendID
        }

        if friend.isFavorite {
            // Slå av favorit
            try await updateFriend(uid: uid, friendId: friendId, data: ["isFavorite": false])
        } else {
            // Kontrollera att det finns plats
            let count = try await favoritesCount(uid: uid)
            if count >= 6 {
                throw FriendServiceError.maxFavoritesReached
            }
            try await updateFriend(uid: uid, friendId: friendId, data: ["isFavorite": true])
        }
    }

    // MARK: - Demo Cleanup

    func removeDemoFriends(uid: String) async throws {
        let snapshot = try await db
            .collection("users")
            .document(uid)
            .collection("friends")
            .whereField("isDemo", isEqualTo: true)
            .getDocuments()
        for document in snapshot.documents {
            try await document.reference.delete()
        }
    }

    // MARK: - Helpers

    func favoritesCount(uid: String) async throws -> Int {
        let snapshot = try await db
            .collection("users")
            .document(uid)
            .collection("friends")
            .whereField("isFavorite", isEqualTo: true)
            .count
            .getAggregation(source: .server)
        return snapshot.count.intValue
    }
}
