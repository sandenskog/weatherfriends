import Foundation
import FirebaseFirestore

struct Friend: Codable, Identifiable {
    @DocumentID var id: String?
    var authUid: String?           // Firebase Auth UID — nil för vänner utan appkonto
    var displayName: String
    var photoURL: String?
    var city: String
    var cityLatitude: Double?
    var cityLongitude: Double?
    var isFavorite: Bool
    var isDemo: Bool
    var hasActiveAlert: Bool?
    var alertSummary: String?
    @ServerTimestamp var lastAlertSentAt: Timestamp?
    @ServerTimestamp var createdAt: Timestamp?
}
