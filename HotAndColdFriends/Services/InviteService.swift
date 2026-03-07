import Foundation
import FirebaseFirestore

// MARK: - InviteDocument

struct InviteDocument: Codable {
    var senderUid: String
    var senderDisplayName: String
    var senderCity: String
    var redeemedBy: [String]
    @ServerTimestamp var createdAt: Timestamp?

    init(senderUid: String, senderDisplayName: String, senderCity: String, redeemedBy: [String] = []) {
        self.senderUid = senderUid
        self.senderDisplayName = senderDisplayName
        self.senderCity = senderCity
        self.redeemedBy = redeemedBy
    }
}

// MARK: - InviteError

enum InviteError: LocalizedError {
    case invalidToken
    case alreadyFriends
    case selfInvite
    case tokenCreationFailed

    var errorDescription: String? {
        switch self {
        case .invalidToken:
            return "This invite link is invalid or has expired."
        case .alreadyFriends:
            return "You are already friends with this person."
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

    /// Gets the existing invite token for the user, or creates a new one if none exists.
    /// Invite tokens are permanent and multi-use (not deleted after redemption).
    func getOrCreateInviteToken(for uid: String, userService: UserService) async throws -> String {
        // Check for existing invite token
        let snapshot = try await db.collection("invites")
            .whereField("senderUid", isEqualTo: uid)
            .limit(to: 1)
            .getDocuments()

        if let existingDoc = snapshot.documents.first {
            return existingDoc.documentID
        }

        // No existing token — create a new one
        return try await createInviteToken(for: uid, userService: userService)
    }

    /// Creates a new invite token for the given user and stores it in Firestore.
    /// Returns the token string (12-char lowercase UUID prefix).
    private func createInviteToken(for uid: String, userService: UserService) async throws -> String {
        guard let user = try await userService.fetchUser(uid: uid) else {
            throw InviteError.tokenCreationFailed
        }

        let token = String(UUID().uuidString.prefix(12)).lowercased()

        let invite = InviteDocument(
            senderUid: uid,
            senderDisplayName: user.displayName,
            senderCity: user.city,
            redeemedBy: []
        )

        try db.collection("invites").document(token).setData(from: invite)
        return token
    }

    /// Builds the invite deep link URL for the given token.
    func inviteURL(token: String) -> URL {
        URL(string: "https://apps.sandenskog.se/invite/\(token)")!
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
    /// The invite document is kept (permanent, multi-use) and the redeemer is added to redeemedBy.
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

        // 3. Check if already redeemed by this user or already friends
        let redeemerFriends = try await friendService.fetchFriends(uid: redeemerUid)
        if invite.redeemedBy.contains(redeemerUid) || redeemerFriends.contains(where: { $0.authUid == invite.senderUid }) {
            throw InviteError.alreadyFriends
        }

        // 4. Get redeemer profile
        guard let redeemer = try await userService.fetchUser(uid: redeemerUid) else {
            throw InviteError.tokenCreationFailed
        }

        // 5. Check if redeemer already has sender as contact-imported friend (merge)
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
        } else {
            // Add sender as friend of redeemer
            let senderAsFriend = Friend(
                authUid: invite.senderUid,
                displayName: invite.senderDisplayName,
                city: invite.senderCity,
                isFavorite: false,
                isDemo: false
            )
            try await friendService.addFriend(uid: redeemerUid, friend: senderAsFriend)
        }

        // 6. Add redeemer as friend of sender (check for existing contact-imported friend too)
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

        // 7. Record redemption (keep invite doc — permanent, multi-use)
        try await db.collection("invites").document(token).updateData([
            "redeemedBy": FieldValue.arrayUnion([redeemerUid])
        ])
    }
}
