import SwiftUI
import PhotosUI
import UIKit
import FirebaseAuth
import FirebaseFirestore

@Observable
@MainActor
class OnboardingViewModel {

    // MARK: - State

    var displayName: String = ""
    var selectedPhotoItem: PhotosPickerItem? {
        didSet {
            Task { await loadPhoto() }
        }
    }
    var profileImage: UIImage?
    var selectedCity: String = ""
    var selectedCityLatitude: Double?
    var selectedCityLongitude: Double?
    var currentStep: Int = 0
    var pendingFriends: [PendingFriend] = []
    var isLoading: Bool = false
    var errorMessage: String?

    // MARK: - Computed

    var canProceedFromName: Bool {
        !displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var canProceedFromLocation: Bool {
        !selectedCity.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    // MARK: - Photo Loading

    func loadPhoto() async {
        guard let item = selectedPhotoItem else {
            profileImage = nil
            return
        }
        do {
            if let data = try await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                profileImage = image
            }
        } catch {
            profileImage = nil
        }
    }

    // MARK: - Complete Onboarding

    func completeOnboarding(uid: String, authManager: AuthManager, userService: UserService, friendService: FriendService) async throws {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        // 1. Ladda upp profilbild om vald
        var photoURL: String? = nil
        if let image = profileImage,
           let imageData = image.jpegData(compressionQuality: 0.8) {
            photoURL = try await userService.uploadProfileImage(uid: uid, imageData: imageData)
        }

        // 2. Bygg AppUser
        let authProvider = Auth.auth().currentUser?.providerData.first?.providerID ?? ""
        let normalizedProvider: String
        if authProvider.contains("apple") {
            normalizedProvider = "apple"
        } else if authProvider.contains("google") {
            normalizedProvider = "google"
        } else if authProvider.contains("facebook") {
            normalizedProvider = "facebook"
        } else {
            normalizedProvider = authProvider
        }

        var newUser = AppUser(
            displayName: displayName.trimmingCharacters(in: .whitespacesAndNewlines),
            photoURL: photoURL,
            city: selectedCity,
            cityLatitude: selectedCityLatitude,
            cityLongitude: selectedCityLongitude,
            authProvider: normalizedProvider
        )

        // Sätt id till Firebase Auth UID via reflection workaround
        // AppUser.id är @DocumentID — vi sätter det via Firestore direkt i UserService
        // men skapar en kopia med rätt id för att uppdatera currentUser
        newUser = AppUser(
            displayName: newUser.displayName,
            photoURL: newUser.photoURL,
            city: newUser.city,
            cityLatitude: newUser.cityLatitude,
            cityLongitude: newUser.cityLongitude,
            authProvider: newUser.authProvider
        )

        // 3. Spara profilen i Firestore
        // UserService.createUserProfile kräver user.id — vi sparar direkt med uid
        let db = Firestore.firestore()
        try await db.collection("users").document(uid).setData([
            "displayName": newUser.displayName,
            "photoURL": newUser.photoURL as Any,
            "city": newUser.city,
            "cityLatitude": newUser.cityLatitude as Any,
            "cityLongitude": newUser.cityLongitude as Any,
            "authProvider": newUser.authProvider
        ], merge: true)

        // 4. Hämta den sparade profilen för att få rätt AppUser med id
        let savedUser = try await userService.fetchUser(uid: uid)

        // 5. Uppdatera AuthManager
        authManager.currentUser = savedUser
        authManager.authState = .authenticated

        // 6. Spara favorit-vänner till Firestore
        for (index, pending) in pendingFriends.enumerated() {
            let friend = Friend(
                displayName: pending.displayName,
                city: pending.city,
                cityLatitude: pending.cityLatitude,
                cityLongitude: pending.cityLongitude,
                isFavorite: index < 6,
                isDemo: false
            )
            try await friendService.addFriend(uid: uid, friend: friend)
        }
    }
}
