import Foundation
import SwiftUI

// MARK: - ClipboardInviteService

@Observable
@MainActor
class ClipboardInviteService {
    var showFriendAddedToast = false
    var friendAddedName = ""

    private let clipboardInvitePrefix = "friendscast-invite:"
    private let maxAgeSec: TimeInterval = 604_800 // 7 days

    private var hasCheckedClipboard: Bool {
        get { UserDefaults.standard.bool(forKey: "hasCheckedClipboardInvite") }
        set { UserDefaults.standard.set(newValue, forKey: "hasCheckedClipboardInvite") }
    }

    /// Checks clipboard for a valid invite token in the format `friendscast-invite:<token>:<unix_timestamp>`.
    /// Returns the token if valid and within 7 days, nil otherwise.
    func checkClipboardForInviteToken() -> String? {
        guard let content = UIPasteboard.general.string else { return nil }
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)

        guard trimmed.hasPrefix(clipboardInvitePrefix) else { return nil }

        let parts = trimmed.split(separator: ":")
        // Expected: ["friendscast-invite", "<token>", "<unix_timestamp>"]
        guard parts.count == 3,
              let timestamp = TimeInterval(parts[2]) else { return nil }

        let age = Date().timeIntervalSince1970 - timestamp
        guard age >= 0, age <= maxAgeSec else { return nil }

        let token = String(parts[1])
        guard !token.isEmpty else { return nil }

        return token
    }

    /// Clears the clipboard if it contains an invite token.
    func clearClipboardInvite() {
        guard let content = UIPasteboard.general.string,
              content.hasPrefix(clipboardInvitePrefix) else { return }
        UIPasteboard.general.string = ""
    }

    /// Checks clipboard once after signup and redeems if a valid invite token is found.
    func checkAndRedeemIfNeeded(
        authUid: String,
        inviteService: InviteService,
        friendService: FriendService,
        userService: UserService
    ) async {
        guard !hasCheckedClipboard else { return }

        guard let token = checkClipboardForInviteToken() else {
            hasCheckedClipboard = true
            return
        }

        do {
            // Look up invite first for sender name
            guard let invite = try await inviteService.lookupInviteToken(token) else {
                hasCheckedClipboard = true
                return
            }

            try await inviteService.redeemInvite(
                token: token,
                redeemerUid: authUid,
                friendService: friendService,
                userService: userService
            )

            friendAddedName = invite.senderDisplayName
            showFriendAddedToast = true
        } catch {
            // Silently fail — clipboard invite is a convenience, not critical
        }

        hasCheckedClipboard = true
        clearClipboardInvite()
    }
}
