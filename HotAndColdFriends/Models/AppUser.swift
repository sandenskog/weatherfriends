import Foundation
import FirebaseFirestore

struct AppUser: Codable, Identifiable {
    /// Mappas till Firestore document ID (= Firebase Auth UID)
    @DocumentID var id: String?
    var displayName: String
    var photoURL: String?
    var city: String
    /// Sparas för WeatherKit-anrop i fas 2
    var cityLatitude: Double?
    /// Sparas för WeatherKit-anrop i fas 2
    var cityLongitude: Double?
    /// Autentiseringsleverantör: "apple" | "google" | "facebook"
    var authProvider: String
    var fcmToken: String?    // FCM push token — sparas av AppDelegate.MessagingDelegate
    @ServerTimestamp var createdAt: Timestamp?
    @ServerTimestamp var updatedAt: Timestamp?

    /// Beräknad egenskap för profilbild-URL
    var profileImageURL: URL? {
        guard let urlString = photoURL else { return nil }
        return URL(string: urlString)
    }
}
