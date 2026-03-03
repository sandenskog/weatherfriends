import Foundation
import FirebaseFirestore
import Observation

@Observable
@MainActor
class ChatViewModel {
    var messages: [ChatMessage] = []
    var messageText: String = ""
    var conversation: Conversation?
    var participantUsers: [String: AppUser] = [:]
    var isLoading = false

    private var userService = UserService()
    private let db = Firestore.firestore()

    func load(conversationId: String, chatService: ChatService, userService: UserService? = nil) async {
        isLoading = true
        defer { isLoading = false }

        chatService.startListeningToMessages(conversationId: conversationId)

        // Hämta konversationsdokumentet
        if let doc = try? await db.collection("conversations").document(conversationId).getDocument() {
            conversation = try? doc.data(as: Conversation.self)
        }

        // Hämta AppUser för varje deltagare
        if let participants = conversation?.participants {
            await fetchParticipantUsers(uids: participants)
        }
    }

    private func fetchParticipantUsers(uids: [String]) async {
        for uid in uids {
            if participantUsers[uid] == nil {
                if let user = try? await userService.fetchUser(uid: uid) {
                    participantUsers[uid] = user
                }
            }
        }
    }

    func send(chatService: ChatService, senderId: String) async {
        let text = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, let conversationId = conversation?.id else { return }
        messageText = ""
        try? await chatService.sendMessage(text, conversationId: conversationId, senderId: senderId)
    }

    func sendSticker(data: WeatherStickerData, chatService: ChatService, senderId: String) async {
        guard let conversationId = conversation?.id else { return }
        try? await chatService.sendWeatherSticker(data: data, conversationId: conversationId, senderId: senderId)
    }

    /// Visar konversationens namn (för navigationTitle)
    func conversationTitle(currentUid: String) -> String {
        guard let conversation else { return "Chatt" }
        if conversation.isGroup {
            return conversation.groupName ?? "Grupp"
        }
        let otherUid = conversation.participants.first { $0 != currentUid } ?? ""
        return participantUsers[otherUid]?.displayName ?? "Chatt"
    }

    /// Returnerar deltagare exklusive current user (för WeatherHeaderView)
    func otherParticipants(currentUid: String) -> [AppUser] {
        guard let conversation else { return [] }
        return conversation.participants
            .filter { $0 != currentUid }
            .compactMap { participantUsers[$0] }
    }
}
