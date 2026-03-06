import Foundation
import FirebaseFirestore

// MARK: - InviteDocument

struct InviteDocument: Codable {
    var senderUid: String
    var senderDisplayName: String
    var senderCity: String
    @ServerTimestamp var createdAt: Timestamp?
}

// MARK: - InviteError

enum InviteError: LocalizedError {
    case invalidToken
    case alreadyRedeemed
    case selfInvite
    case tokenCreationFailed

    var errorDescription: String? {
        switch self {
        case .invalidToken:
            return "This invite link is invalid or has expired."
        case .alreadyRedeemed:
            return "This invite link has already been used."
        case .selfInvite:
            return "You can't use your own invite link."
        case .tokenCreationFailed:
            return "Failed to create invite link. Please try again."
        }
    }
}

// MARK: - InviteService

@Observable
@MainActor
class InviteService {
    private let db = Firestore.firestore()

    /// Creates an invite token for the given user and stores it in Firestore.
    /// Returns the token string (12-char lowercase UUID prefix).
    func createInviteToken(for uid: String, userService: UserService) async throws -> String {
        guard let user = try await userService.fetchUser(uid: uid) else {
            throw InviteError.tokenCreationFailed
        }

        let token = String(UUID().uuidString.prefix(12)).lowercased()

        let invite = InviteDocument(
            senderUid: uid,
            senderDisplayName: user.displayName,
            senderCity: user.city
        )

        try db.collection("invites").document(token).setData(from: invite)
        return token
    }

    /// Builds the invite deep link URL for the given token.
    func inviteURL(token: String) -> URL {
        URL(string: "hotandcold://invite/\(token)")!
    }

    /// Looks up an invite document by token.
    func lookupInviteToken(_ token: String) async throws -> InviteDocument? {
        let doc = try await db.collection("invites").document(token).getDocument()
        guard doc.exists else { return nil }
        return try doc.data(as: InviteDocument.self)
    }

    /// Redeems an invite: creates mutual friendship between sender and redeemer.
    /// If the redeemer already has a contact-imported friend matching the sender's displayName,
    /// that friend's authUid is updated instead of creating a duplicate.
    /// The invite document is deleted after successful redemption.
    func redeemInvite(
        token: String,
        redeemerUid: String,
        friendService: FriendService,
        userService: UserService
    ) async throws {
        // 1. Look up invite
        guard let invite = try await lookupInviteToken(token) else {
            throw InviteError.invalidToken
        }

        // 2. Prevent self-invite
        guard invite.senderUid != redeemerUid else {
            throw InviteError.selfInvite
        }

        // 3. Get redeemer profile
        guard let redeemer = try await userService.fetchUser(uid: redeemerUid) else {
            throw InviteError.tokenCreationFailed
        }

        // 4. Check if redeemer already has sender as friend (merge contact-imported friend)
        let redeemerFriends = try await friendService.fetchFriends(uid: redeemerUid)
        let existingFriend = redeemerFriends.first { friend in
            friend.displayName == invite.senderDisplayName && friend.authUid == nil
        }

        if let existing = existingFriend, let friendId = existing.id {
            // Update contact-imported friend with real authUid
            try await db
                .collection("users")
                .document(redeemerUid)
                .collection("friends")
                .document(friendId)
                .updateData(["authUid": invite.senderUid])
        } else if !redeemerFriends.contains(where: { $0.authUid == invite.senderUid }) {
            // Add sender as friend of redeemer (only if not already friends)
            let senderAsFriend = Friend(
                authUid: invite.senderUid,
                displayName: invite.senderDisplayName,
                city: invite.senderCity,
                isFavorite: false,
                isDemo: false
            )
            try await friendService.addFriend(uid: redeemerUid, friend: senderAsFriend)
        }

        // 5. Add redeemer as friend of sender (check for existing contact-imported friend too)
        let senderFriends = try await friendService.fetchFriends(uid: invite.senderUid)
        let existingSenderFriend = senderFriends.first { friend in
            friend.displayName == redeemer.displayName && friend.authUid == nil
        }

        if let existing = existingSenderFriend, let friendId = existing.id {
            // Update contact-imported friend with real authUid
            try await db
                .collection("users")
                .document(invite.senderUid)
                .collection("friends")
                .document(friendId)
                .updateData(["authUid": redeemerUid])
        } else if !senderFriends.contains(where: { $0.authUid == redeemerUid }) {
            // Add redeemer as friend of sender
            let redeemerAsFriend = Friend(
                authUid: redeemerUid,
                displayName: redeemer.displayName,
                city: redeemer.city,
                isFavorite: false,
                isDemo: false
            )
            try await friendService.addFriend(uid: invite.senderUid, friend: redeemerAsFriend)
        }

        // 6. Delete invite doc after successful redemption
        try await db.collection("invites").document(token).delete()
    }
}
