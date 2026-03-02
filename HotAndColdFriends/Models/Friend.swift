import Foundation
import FirebaseFirestore

struct Friend: Codable, Identifiable {
    @DocumentID var id: String?
    var displayName: String
    var photoURL: String?
    var city: String
    var cityLatitude: Double?
    var cityLongitude: Double?
    var isFavorite: Bool
    var isDemo: Bool
    @ServerTimestamp var createdAt: Timestamp?
}
