import Foundation

struct Friend: Codable, Identifiable {
    var id: String = UUID().uuidString
    var authUid: String?
    var displayName: String
    var photoURL: String?
    var city: String
    var cityLatitude: Double?
    var cityLongitude: Double?
    var isFavorite: Bool = false
    var isDemo: Bool = false
    var hasActiveAlert: Bool?
    var alertSummary: String?
    var createdAt: Date?
}
