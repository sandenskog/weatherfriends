import FirebaseFirestore

struct Conversation: Codable, Identifiable {
    @DocumentID var id: String?
    var participants: [String]          // uid-array
    var isGroup: Bool
    var groupName: String?
    var lastMessage: String?
    var lastMessageAt: Timestamp?
    var lastMessageSenderId: String?
    @ServerTimestamp var createdAt: Timestamp?
}
