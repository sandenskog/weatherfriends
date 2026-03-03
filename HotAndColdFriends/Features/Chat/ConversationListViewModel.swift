import Foundation
import FirebaseFirestore
import Observation
import WeatherKit

@Observable
@MainActor
class ConversationListViewModel {
    var conversations: [Conversation] = []
    var usersMap: [String: AppUser] = [:]
    var blockedUserIds: Set<String> = Set()
    var isLoading = false

    private var userService = UserService()

    func load(uid: String, chatService: ChatService, friendService: FriendService) async {
        isLoading = true
        defer { isLoading = false }

        async let blockedTask: Set<String> = {
            (try? await chatService.fetchBlockedUserIds(uid: uid)) ?? []
        }()

        blockedUserIds = await blockedTask

        chatService.startListeningToConversations(uid: uid)

        // Bygg usersMap från konversationsdeltagare
        await refreshUsersMap(conversations: chatService.conversations, currentUid: uid)
    }

    func refreshUsersMapIfNeeded(conversations: [Conversation], currentUid: String) async {
        await refreshUsersMap(conversations: conversations, currentUid: currentUid)
    }

    private func refreshUsersMap(conversations: [Conversation], currentUid: String) async {
        let allUids = Set(conversations.flatMap { $0.participants }).subtracting([currentUid])
        let missingUids = allUids.filter { usersMap[$0] == nil }
        for uid in missingUids {
            if let user = try? await userService.fetchUser(uid: uid) {
                usersMap[uid] = user
            }
        }
    }

    /// Returnerar visningsnamn för en konversation
    func displayName(for conversation: Conversation, currentUid: String) -> String {
        if conversation.isGroup {
            return conversation.groupName ?? "Grupp"
        }
        let otherUid = conversation.participants.first { $0 != currentUid } ?? ""
        return usersMap[otherUid]?.displayName ?? "Okänd"
    }

    /// Returnerar den andra deltagarens AppUser (för 1-till-1)
    func otherUser(for conversation: Conversation, currentUid: String) -> AppUser? {
        guard !conversation.isGroup else { return nil }
        let otherUid = conversation.participants.first { $0 != currentUid } ?? ""
        return usersMap[otherUid]
    }

    /// Filtrerar bort konversationer där alla andra deltagare är blockerade
    func filteredConversations(from conversations: [Conversation], currentUid: String) -> [Conversation] {
        conversations.filter { conversation in
            let others = conversation.participants.filter { $0 != currentUid }
            return !others.allSatisfy { blockedUserIds.contains($0) }
        }
    }

    /// Formaterar tidsstämpel som "HH:mm" eller datum om äldre
    func formattedTime(_ timestamp: Timestamp?) -> String {
        guard let timestamp else { return "" }
        let date = timestamp.dateValue()
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm"
            return formatter.string(from: date)
        } else if calendar.isDateInYesterday(date) {
            return "Igår"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "d MMM"
            return formatter.string(from: date)
        }
    }
}
