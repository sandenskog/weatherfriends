import Foundation
import FirebaseFirestore
import Observation

@Observable
@MainActor
class ChatService {
    var conversations: [Conversation] = []
    var messages: [ChatMessage] = []

    nonisolated(unsafe) private var conversationsListener: ListenerRegistration?
    nonisolated(unsafe) private var messagesListener: ListenerRegistration?

    private let db = Firestore.firestore()

    // MARK: - Konversationslyssnare

    func startListeningToConversations(uid: String) {
        conversationsListener?.remove()
        conversationsListener = db.collection("conversations")
            .whereField("participants", arrayContains: uid)
            .order(by: "lastMessageAt", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self, let snapshot else { return }
                self.conversations = snapshot.documents.compactMap {
                    try? $0.data(as: Conversation.self)
                }
            }
    }

    // MARK: - Meddelandelyssnare

    func startListeningToMessages(conversationId: String) {
        messagesListener?.remove()
        messagesListener = db.collection("conversations")
            .document(conversationId)
            .collection("messages")
            .order(by: "sentAt", descending: false)
            .limit(toLast: 50)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self, let snapshot else { return }
                self.messages = snapshot.documents.compactMap {
                    try? $0.data(as: ChatMessage.self)
                }
            }
    }

    func stopListeningToMessages() {
        messagesListener?.remove()
        messagesListener = nil
    }

    func stopAll() {
        conversationsListener?.remove()
        conversationsListener = nil
        messagesListener?.remove()
        messagesListener = nil
    }

    // MARK: - Skicka textmeddelande

    func sendMessage(_ text: String, conversationId: String, senderId: String) async throws {
        let message = ChatMessage(
            id: nil,
            senderId: senderId,
            type: .text,
            text: text,
            weatherData: nil,
            sentAt: nil
        )
        let ref = db.collection("conversations").document(conversationId).collection("messages")
        try ref.addDocument(from: message)

        try await db.collection("conversations").document(conversationId).updateData([
            "lastMessage": text,
            "lastMessageAt": FieldValue.serverTimestamp(),
            "lastMessageSenderId": senderId
        ])
    }

    // MARK: - Skicka vädersticker

    func sendWeatherSticker(data: WeatherStickerData, conversationId: String, senderId: String) async throws {
        let message = ChatMessage(
            id: nil,
            senderId: senderId,
            type: .weatherSticker,
            text: nil,
            weatherData: data,
            sentAt: nil
        )
        let ref = db.collection("conversations").document(conversationId).collection("messages")
        try ref.addDocument(from: message)

        try await db.collection("conversations").document(conversationId).updateData([
            "lastMessage": "Väder-sticker",
            "lastMessageAt": FieldValue.serverTimestamp(),
            "lastMessageSenderId": senderId
        ])
    }

    // MARK: - Hantera 1-till-1 konversation

    func getOrCreateDirectConversation(currentUid: String, friendUid: String) async throws -> String {
        let conversationId = [currentUid, friendUid].sorted().joined(separator: "_")
        let docRef = db.collection("conversations").document(conversationId)
        let snapshot = try await docRef.getDocument()

        if !snapshot.exists {
            let conversation = Conversation(
                id: conversationId,
                participants: [currentUid, friendUid],
                isGroup: false,
                groupName: nil,
                lastMessage: nil,
                lastMessageAt: nil,
                lastMessageSenderId: nil,
                createdAt: nil
            )
            try docRef.setData(from: conversation)
        }

        return conversationId
    }

    // MARK: - Skapa gruppkonversation

    func createGroupConversation(creatorUid: String, participantUids: [String], groupName: String?) async throws -> String {
        let allParticipants = ([creatorUid] + participantUids)
        guard allParticipants.count <= 20 else {
            throw ChatServiceError.tooManyParticipants
        }

        let conversation = Conversation(
            id: nil,
            participants: allParticipants,
            isGroup: true,
            groupName: groupName,
            lastMessage: nil,
            lastMessageAt: nil,
            lastMessageSenderId: nil,
            createdAt: nil
        )

        let ref = try db.collection("conversations").addDocument(from: conversation)
        return ref.documentID
    }

    // MARK: - Blockering

    func blockUser(uid: String, blockedUid: String) async throws {
        try await db.collection("users").document(uid)
            .collection("blockedUsers").document(blockedUid)
            .setData(["blockedAt": FieldValue.serverTimestamp()])
    }

    func unblockUser(uid: String, blockedUid: String) async throws {
        try await db.collection("users").document(uid)
            .collection("blockedUsers").document(blockedUid)
            .delete()
    }

    func isBlocked(uid: String, blockedUid: String) async -> Bool {
        let snapshot = try? await db.collection("users").document(uid)
            .collection("blockedUsers").document(blockedUid)
            .getDocument()
        return snapshot?.exists ?? false
    }

    func fetchBlockedUserIds(uid: String) async throws -> Set<String> {
        let snapshot = try await db.collection("users").document(uid)
            .collection("blockedUsers")
            .getDocuments()
        return Set(snapshot.documents.map { $0.documentID })
    }

    // MARK: - Rapportering

    func reportMessage(report: Report) async throws {
        try db.collection("reports").addDocument(from: report)
    }
}

// MARK: - Errors

enum ChatServiceError: Error {
    case tooManyParticipants
}
