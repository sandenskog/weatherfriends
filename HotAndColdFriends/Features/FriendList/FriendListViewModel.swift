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
            if fetchedFriends.isEmpty {
                // Visa alltid demo-data om inga riktiga vänner finns
                friends = DemoFriendService.demoFriends
                showDemoBanner = true
            } else {
                friends = fetchedFriends
                showDemoBanner = friends.contains { $0.isDemo }
            }
            print("📋 Laddar \(friends.count) vänner (demo: \(showDemoBanner))")

            let weatherItems = await fetchWeatherParallel(for: friends, weatherService: weatherService)
            let sorted = weatherItems.sorted {
                ($0.temperatureCelsius ?? -999) > ($1.temperatureCelsius ?? -999)
            }
            favorites = sorted.filter { $0.friend.isFavorite }
            others = sorted.filter { !$0.friend.isFavorite }
        } catch {
            errorMessage = "Kunde inte hämta vänner: \(error.localizedDescription)"
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
                    others.sort { ($0.temperatureCelsius ?? -999) > ($1.temperatureCelsius ?? -999) }
                }
            } else {
                // Flytta från others till favoriter
                if let idx = others.firstIndex(where: { $0.friend.id == friend.id }) {
                    var item = others.remove(at: idx)
                    var updatedFriend = item.friend
                    updatedFriend.isFavorite = true
                    item = FriendWeather(friend: updatedFriend, weather: item.weather)
                    favorites.append(item)
                    favorites.sort { ($0.temperatureCelsius ?? -999) > ($1.temperatureCelsius ?? -999) }
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
                        print("⚠️ WeatherKit fel för \(friend.displayName) (\(lat), \(lon)): \(error)")
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
