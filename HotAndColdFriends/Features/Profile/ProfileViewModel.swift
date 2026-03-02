import SwiftUI

@Observable
@MainActor
class ProfileViewModel {

    // MARK: - State

    var user: AppUser?
    var isLoading: Bool = false
    var errorMessage: String?

    // MARK: - Load Profile

    func loadProfile(uid: String, userService: UserService) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            user = try await userService.fetchUser(uid: uid)
        } catch {
            errorMessage = "Kunde inte ladda profilen."
        }
    }

    // MARK: - Update Profile

    func updateProfile(
        uid: String,
        displayName: String,
        city: String,
        lat: Double?,
        lon: Double?,
        photoData: Data?,
        userService: UserService
    ) async throws {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        var updatedData: [String: Any] = [
            "displayName": displayName.trimmingCharacters(in: .whitespacesAndNewlines),
            "city": city
        ]

        if let lat = lat {
            updatedData["cityLatitude"] = lat
        }
        if let lon = lon {
            updatedData["cityLongitude"] = lon
        }

        // Ladda upp ny bild om tillgänglig
        if let photoData = photoData {
            let photoURL = try await userService.uploadProfileImage(uid: uid, imageData: photoData)
            updatedData["photoURL"] = photoURL
        }

        try await userService.updateUser(uid: uid, data: updatedData)

        // Uppdatera lokalt cache
        if var u = user {
            u.displayName = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
            u.city = city
            u.cityLatitude = lat
            u.cityLongitude = lon
            if let photoURL = updatedData["photoURL"] as? String {
                u.photoURL = photoURL
            }
            user = u
        }
    }
}
