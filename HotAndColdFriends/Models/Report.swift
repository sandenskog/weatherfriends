import FirebaseFirestore

struct Report: Codable, Identifiable {
    @DocumentID var id: String?
    var reporterUid: String
    var reportedUid: String
    var messageId: String
    var conversationId: String
    var reason: String
    @ServerTimestamp var createdAt: Timestamp?
}
