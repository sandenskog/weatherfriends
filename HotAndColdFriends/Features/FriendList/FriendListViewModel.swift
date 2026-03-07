import Foundation
import Observation
import WidgetKit

@Observable
@MainActor
class FriendListViewModel {
    var favorites: [FriendWeather] = []
    var others: [FriendWeather] = []
    var myWeather: FriendWeather?
    var isLoading = false
    var errorMessage: String?
    var showDemoBanner = false
    var refreshToken = UUID()

    // MARK: - Load

    func load(uid: String, friendService: FriendService, weatherService: AppWeatherService, currentUser: AppUser? = nil) async {
        isLoading = true
        defer { isLoading = false }
        errorMessage = nil

        do {
            let fetchedFriends = try await friendService.fetchFriends(uid: uid)

            let friends: [Friend]
            if fetchedFriends.isEmpty {
                // Visa alltid demo-data om inga riktiga vänner finns
                friends = DemoFriendService.demoFriends
                showDemoBanner = true
            } else {
                friends = fetchedFriends
                showDemoBanner = friends.contains { $0.isDemo }
            }

            let weatherItems = await fetchWeatherParallel(for: friends, weatherService: weatherService)
            let sorted = weatherItems.sorted {
                ($0.temperatureCelsius ?? -999) > ($1.temperatureCelsius ?? -999)
            }
            favorites = sorted.filter { $0.friend.isFavorite }
            others = sorted.filter { !$0.friend.isFavorite }

            // Hämta användarens eget väder
            if let user = currentUser,
               let lat = user.cityLatitude,
               let lon = user.cityLongitude {
                let meFriend = Friend(
                    id: user.id,
                    authUid: user.id,
                    displayName: user.displayName,
                    photoURL: user.photoURL,
                    city: user.city,
                    cityLatitude: lat,
                    cityLongitude: lon
                )
                do {
                    let weather = try await weatherService.currentWeather(latitude: lat, longitude: lon)
                    myWeather = FriendWeather(friend: meFriend, weather: weather)
                } catch {
                    myWeather = FriendWeather(friend: meFriend, weather: nil)
                }
            }

            // Skriv favoriter till delad UserDefaults för widget
            updateWidgetData(favorites: self.favorites)
        } catch {
            errorMessage = "Kunde inte hämta vänner: \(error.localizedDescription)"
        }
    }

    // MARK: - Toggle Favorite

    func toggleFavorite(uid: String, friend: Friend, friendService: FriendService) async {
        if friend.isDemo {
            // Demo-vänner saknar Firestore-ID — hantera lokalt
            toggleFavoriteLocally(friend: friend)
            return
        }

        do {
            try await friendService.toggleFavorite(uid: uid, friend: friend)
            toggleFavoriteLocally(friend: friend)
        } catch FriendServiceError.maxFavoritesReached {
            errorMessage = "Du har redan 6 favoriter. Ta bort en för att lägga till en ny."
        } catch {
            errorMessage = "Kunde inte uppdatera favorit: \(error.localizedDescription)"
        }
    }

    private func toggleFavoriteLocally(friend: Friend) {
        if friend.isFavorite {
            if let idx = favorites.firstIndex(where: { $0.friend.id == friend.id && $0.friend.displayName == friend.displayName }) {
                var item = favorites.remove(at: idx)
                var updatedFriend = item.friend
                updatedFriend.isFavorite = false
                item = FriendWeather(friend: updatedFriend, weather: item.weather)
                others.append(item)
                others.sort { ($0.temperatureCelsius ?? -999) > ($1.temperatureCelsius ?? -999) }
            }
        } else {
            // Kontrollera max 6 favoriter lokalt
            if favorites.count >= 6 {
                errorMessage = "Du har redan 6 favoriter. Ta bort en för att lägga till en ny."
                return
            }
            if let idx = others.firstIndex(where: { $0.friend.id == friend.id && $0.friend.displayName == friend.displayName }) {
                var item = others.remove(at: idx)
                var updatedFriend = item.friend
                updatedFriend.isFavorite = true
                item = FriendWeather(friend: updatedFriend, weather: item.weather)
                favorites.append(item)
                favorites.sort { ($0.temperatureCelsius ?? -999) > ($1.temperatureCelsius ?? -999) }
            }
        }
    }

    // MARK: - Remove Demo Data

    func removeDemoData(uid: String, friendService: FriendService) async {
        do {
            try await friendService.removeDemoFriends(uid: uid)
            showDemoBanner = false
            favorites = favorites.filter { !$0.friend.isDemo }
            others = others.filter { !$0.friend.isDemo }
        } catch {
            errorMessage = "Kunde inte ta bort exempeldata: \(error.localizedDescription)"
        }
    }

    // MARK: - Refresh

    func refresh(uid: String, friendService: FriendService, weatherService: AppWeatherService, currentUser: AppUser? = nil) async {
        await weatherService.clearCache()
        await load(uid: uid, friendService: friendService, weatherService: weatherService, currentUser: currentUser)
    }

    // MARK: - Widget Data

    private func updateWidgetData(favorites: [FriendWeather]) {
        let entries: [WidgetFriendEntry] = favorites.compactMap { fw in
            guard let id = fw.friend.id else { return nil }
            let temp = fw.temperatureCelsius
            let rgb: [Double]
            if let celsius = temp {
                if celsius < 0 {
                    rgb = [0.6, 0.85, 1.0]   // isblå
                } else if celsius < 10 {
                    rgb = [0.4, 0.7, 0.95]   // kylig blå
                } else if celsius < 20 {
                    rgb = [0.3, 0.75, 0.45]  // grön
                } else if celsius < 28 {
                    rgb = [1.0, 0.65, 0.2]   // orange
                } else {
                    rgb = [1.0, 0.3, 0.2]    // röd
                }
            } else {
                rgb = [0.6, 0.6, 0.6]        // grå fallback
            }
            return WidgetFriendEntry(
                id: id,
                displayName: fw.friend.displayName,
                city: fw.friend.city,
                temperatureCelsius: temp,
                symbolName: fw.symbolName,
                temperatureColorRGB: rgb
            )
        }
        if let data = try? JSONEncoder().encode(entries) {
            let defaults = UserDefaults(suiteName: "group.se.sandenskog.hotandcoldfriends")
            defaults?.set(data, forKey: "widgetFavorites")
        }
        WidgetCenter.shared.reloadTimelines(ofKind: "HotAndColdFriendsWidget")
    }

    // MARK: - Private helpers

    private func fetchWeatherParallel(for friends: [Friend], weatherService: AppWeatherService) async -> [FriendWeather] {
        await withTaskGroup(of: FriendWeather.self) { group in
            for friend in friends {
                group.addTask {
                    guard let lat = friend.cityLatitude, let lon = friend.cityLongitude else {
                        return FriendWeather(friend: friend, weather: nil)
                    }
                    do {
                        let weather = try await weatherService.currentWeather(latitude: lat, longitude: lon)
                        return FriendWeather(friend: friend, weather: weather)
                    } catch {
                        return FriendWeather(friend: friend, weather: nil)
                    }
                }
            }

            var results: [FriendWeather] = []
            for await item in group {
                results.append(item)
            }
            return results
        }
    }
}
