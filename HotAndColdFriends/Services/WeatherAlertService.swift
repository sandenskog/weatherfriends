import Foundation
import WeatherKit
import CoreLocation
import FirebaseFirestore

/// Kontrollerar extremvader (WeatherKit weatherAlerts) for varje van med koordinater
/// och skriver hasActiveAlert/alertSummary till Firestore.
/// Anropas vid app-start fran HotAndColdFriendsApp .task{}.
@MainActor
class WeatherAlertService {
    private let weatherService = WeatherKit.WeatherService.shared
    private let db = Firestore.firestore()

    /// Kontrollera weatherAlerts for alla vanner med koordinater och uppdatera Firestore.
    func checkAlertsForFriends(uid: String, friends: [Friend]) async {
        for friend in friends {
            guard let friendId = friend.id,
                  let lat = friend.cityLatitude,
                  let lon = friend.cityLongitude else { continue }

            // Skip demo-vanner
            guard !friend.isDemo else { continue }

            do {
                let location = CLLocation(latitude: lat, longitude: lon)
                let weather = try await weatherService.weather(for: location, including: .alerts)

                // weather ar [WeatherAlert]? — kan vara nil for regioner utan stod (t.ex. Sverige)
                // Detta ar INTE ett fel — hantera som "inga aktiva varningar"
                let hasAlert: Bool
                let summary: String?

                if let alerts = weather, !alerts.isEmpty {
                    hasAlert = true
                    // Anvand forsta alertens summary som notistext
                    summary = alerts.first?.summary ?? "Extremt vader"
                } else {
                    hasAlert = false
                    summary = nil
                }

                // Skriv till Firestore — detta triggar Cloud Function om hasActiveAlert andras
                var updateData: [String: Any] = [
                    "hasActiveAlert": hasAlert
                ]
                if let summary {
                    updateData["alertSummary"] = summary
                } else {
                    updateData["alertSummary"] = FieldValue.delete()
                }

                try await db.collection("users")
                    .document(uid)
                    .collection("friends")
                    .document(friendId)
                    .updateData(updateData)

            } catch {
                // WeatherKit-fel ska INTE krascha appen — fortsatt med nasta van
                continue
            }
        }
    }
}
