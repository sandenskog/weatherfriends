import Foundation
import Observation

@Observable
@MainActor
class FriendListViewModel {
    var favorites: [FriendWeather] = []
    var others: [FriendWeather] = []
    var isLoading = false
    var errorMessage: String?
    var showDemoBanner = false
    var refreshToken = UUID()

    // MARK: - Load

    func load(uid: String, friendService: FriendService, weatherService: AppWeatherService) async {
        isLoading = true
        defer { isLoading = false }
        errorMessage = nil

        do {
            let fetchedFriends = try await friendService.fetchFriends(uid: uid)

            let friends: [Friend]
            if fetchedFriends.isEmpty && !UserDefaults.standard.bool(forKey: "hideDemoData") {
                friends = DemoFriendService.demoFriends
                showDemoBanner = true
            } else {
                friends = fetchedFriends
                showDemoBanner = friends.contains { $0.isDemo }
            }

            let weatherItems = try await fetchWeatherParallel(for: friends, weatherService: weatherService)
            let sorted = weatherItems.sorted { $0.temperatureCelsius > $1.temperatureCelsius }
            favorites = sorted.filter { $0.friend.isFavorite }
            others = sorted.filter { !$0.friend.isFavorite }
        } catch {
            errorMessage = "Kunde inte hämta väderdata: \(error.localizedDescription)"
        }
    }

    // MARK: - Toggle Favorite

    func toggleFavorite(uid: String, friend: Friend, friendService: FriendService) async {
        do {
            try await friendService.toggleFavorite(uid: uid, friend: friend)

            // Uppdatera lokalt
            if friend.isFavorite {
                // Ta bort från favoriter, flytta till others
                if let idx = favorites.firstIndex(where: { $0.friend.id == friend.id }) {
                    var item = favorites.remove(at: idx)
                    var updatedFriend = item.friend
                    updatedFriend.isFavorite = false
                    item = FriendWeather(friend: updatedFriend, weather: item.weather)
                    others.append(item)
                    others.sort { $0.temperatureCelsius > $1.temperatureCelsius }
                }
            } else {
                // Flytta från others till favoriter
                if let idx = others.firstIndex(where: { $0.friend.id == friend.id }) {
                    var item = others.remove(at: idx)
                    var updatedFriend = item.friend
                    updatedFriend.isFavorite = true
                    item = FriendWeather(friend: updatedFriend, weather: item.weather)
                    favorites.append(item)
                    favorites.sort { $0.temperatureCelsius > $1.temperatureCelsius }
                }
            }
        } catch FriendServiceError.maxFavoritesReached {
            errorMessage = "Du har redan 6 favoriter. Ta bort en för att lägga till en ny."
        } catch {
            errorMessage = "Kunde inte uppdatera favorit: \(error.localizedDescription)"
        }
    }

    // MARK: - Remove Demo Data

    func removeDemoData(uid: String, friendService: FriendService) async {
        do {
            try await friendService.removeDemoFriends(uid: uid)
            UserDefaults.standard.set(true, forKey: "hideDemoData")
            showDemoBanner = false
            favorites = favorites.filter { !$0.friend.isDemo }
            others = others.filter { !$0.friend.isDemo }
        } catch {
            errorMessage = "Kunde inte ta bort exempeldata: \(error.localizedDescription)"
        }
    }

    // MARK: - Refresh

    func refresh(uid: String, friendService: FriendService, weatherService: AppWeatherService) async {
        await weatherService.clearCache()
        await load(uid: uid, friendService: friendService, weatherService: weatherService)
    }

    // MARK: - Private helpers

    private func fetchWeatherParallel(for friends: [Friend], weatherService: AppWeatherService) async throws -> [FriendWeather] {
        try await withThrowingTaskGroup(of: FriendWeather?.self) { group in
            for friend in friends {
                guard let lat = friend.cityLatitude, let lon = friend.cityLongitude else {
                    continue
                }
                group.addTask {
                    let weather = try await weatherService.currentWeather(latitude: lat, longitude: lon)
                    return FriendWeather(friend: friend, weather: weather)
                }
            }

            var results: [FriendWeather] = []
            for try await item in group {
                if let item {
                    results.append(item)
                }
            }
            return results
        }
    }
}
