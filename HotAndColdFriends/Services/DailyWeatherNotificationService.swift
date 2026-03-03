import Foundation
import UserNotifications

// MARK: - DailyWeatherNotificationService

@MainActor
class DailyWeatherNotificationService {
    private let notificationCenter = UNUserNotificationCenter.current()
    private let identifier = "daily-weather-summary"

    /// Schemalägger daglig notis kl 07:00 med favoriters väderdata.
    /// Anropas vid varje app-start efter att väderdata laddats.
    /// Ersätter alltid befintlig schemalagd notis (undviker dubbletter).
    func schedule(favorites: [FriendWeather]) async {
        // Schemalägg inte om inga favoriter finns
        guard !favorites.isEmpty else {
            cancel()
            return
        }

        // Kontrollera att notis-behörighet är beviljad
        let settings = await notificationCenter.notificationSettings()
        guard settings.authorizationStatus == .authorized else { return }

        // Bygg notis-body: "Anna 28° · Erik 12° · Lisa -3°"
        let summary = favorites.compactMap { fw -> String? in
            guard fw.temperatureCelsius != nil else { return nil }
            let firstName = fw.friend.displayName
                .components(separatedBy: " ")
                .first ?? fw.friend.displayName
            return "\(firstName) \(fw.temperatureFormatted)"
        }.joined(separator: " \u{00B7} ")  // middle dot separator

        guard !summary.isEmpty else {
            cancel()
            return
        }

        let content = UNMutableNotificationContent()
        content.title = "God morgon! \u{2600}\u{FE0F}"  // sol-emoji
        content.body = summary
        content.sound = .default

        var dateComponents = DateComponents()
        dateComponents.calendar = Calendar.current
        dateComponents.hour = 7
        dateComponents.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        // Ta bort befintlig notis innan ny schemaläggs — undviker dubbletter
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [identifier])

        do {
            try await notificationCenter.add(request)
        } catch {
            // Notis-schemaläggning är icke-kritisk — logga men propagera ej
            print("[DailyWeatherNotificationService] Kunde inte schemalägga notis: \(error)")
        }
    }

    /// Avbryter schemalagd daglig notis.
    func cancel() {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [identifier])
    }
}
