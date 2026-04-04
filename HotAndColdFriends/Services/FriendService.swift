import Foundation
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
    private let storageKey = "friendscast.friends"

    // MARK: - Fetch

    func fetchFriends(uid: String = "") async throws -> [Friend] {
        return loadFromDisk().sorted { $0.displayName < $1.displayName }
    }

    // MARK: - Add

    func addFriend(uid: String = "", friend: Friend) async throws {
        if friend.isFavorite {
            let count = loadFromDisk().filter { $0.isFavorite }.count
            if count >= 6 { throw FriendServiceError.maxFavoritesReached }
        }
        var friends = loadFromDisk()
        var newFriend = friend
        if newFriend.id.isEmpty { newFriend.id = UUID().uuidString }
        newFriend.createdAt = Date()
        friends.append(newFriend)
        saveToDisk(friends)
    }

    // MARK: - Update

    func updateFriend(uid: String = "", friendId: String, data: [String: Any]) async throws {
        var friends = loadFromDisk()
        guard let idx = friends.firstIndex(where: { $0.id == friendId }) else { return }
        if let isFavorite = data["isFavorite"] as? Bool {
            friends[idx].isFavorite = isFavorite
        }
        if let hasActiveAlert = data["hasActiveAlert"] as? Bool {
            friends[idx].hasActiveAlert = hasActiveAlert
        }
        if let alertSummary = data["alertSummary"] as? String {
            friends[idx].alertSummary = alertSummary
        }
        saveToDisk(friends)
    }

    // MARK: - Remove

    func removeFriend(uid: String = "", friendId: String) async throws {
        var friends = loadFromDisk()
        friends.removeAll { $0.id == friendId }
        saveToDisk(friends)
    }

    // MARK: - Toggle Favorite

    func toggleFavorite(uid: String = "", friend: Friend) async throws {
        var friends = loadFromDisk()
        guard let idx = friends.firstIndex(where: { $0.id == friend.id }) else { return }
        if friends[idx].isFavorite {
            friends[idx].isFavorite = false
        } else {
            let count = friends.filter { $0.isFavorite }.count
            if count >= 6 { throw FriendServiceError.maxFavoritesReached }
            friends[idx].isFavorite = true
        }
        saveToDisk(friends)
    }

    // MARK: - Demo Cleanup

    func removeDemoFriends(uid: String = "") async throws {
        var friends = loadFromDisk()
        friends.removeAll { $0.isDemo }
        saveToDisk(friends)
    }

    // MARK: - Helpers

    func favoritesCount(uid: String = "") async throws -> Int {
        loadFromDisk().filter { $0.isFavorite }.count
    }

    // MARK: - Disk I/O

    private func loadFromDisk() -> [Friend] {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let friends = try? JSONDecoder().decode([Friend].self, from: data) else {
            return []
        }
        return friends
    }

    private func saveToDisk(_ friends: [Friend]) {
        guard let data = try? JSONEncoder().encode(friends) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }
}
