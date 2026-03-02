import Contacts
import FirebaseStorage
import FirebaseFunctions
import Foundation
import Observation

// MARK: - Fel

enum ContactImportError: LocalizedError {
    case accessDenied

    var errorDescription: String? {
        switch self {
        case .accessDenied:
            return "Åtkomst till kontakter nekad. Gå till Inställningar → Hot & Cold Friends → Kontakter för att aktivera."
        }
    }
}

// MARK: - ImportableContact

struct ImportableContact: Identifiable {
    let id: String  // CNContact.identifier
    let givenName: String
    let familyName: String
    let fullName: String  // "\(givenName) \(familyName)".trimmingCharacters(in: .whitespaces)
    let phoneNumbers: [String]
    let emailAddresses: [String]
    let postalCity: String
    let postalCountry: String
    let thumbnailImageData: Data?
    let hasAddress: Bool

    /// Stad-hint för visning i importlistan (stad, land eller "Adress finns")
    var locationHint: String {
        if hasAddress && !postalCity.isEmpty {
            return "\(postalCity), \(postalCountry)"
        }
        if hasAddress {
            return "Adress finns"
        }
        if let phone = phoneNumbers.first, phone.hasPrefix("+") {
            // Visa telefonnummer-prefix som ledtråd
            let prefix = String(phone.prefix(4))
            return "Tel: \(prefix)..."
        }
        return ""
    }
}

// MARK: - ContactImportService

@Observable @MainActor class ContactImportService {

    // MARK: - Statiska nycklar

    nonisolated static let keysToFetch: [CNKeyDescriptor] = [
        CNContactGivenNameKey as CNKeyDescriptor,
        CNContactFamilyNameKey as CNKeyDescriptor,
        CNContactPhoneNumbersKey as CNKeyDescriptor,
        CNContactEmailAddressesKey as CNKeyDescriptor,
        CNContactPostalAddressesKey as CNKeyDescriptor,
        CNContactThumbnailImageDataKey as CNKeyDescriptor,
        CNContactIdentifierKey as CNKeyDescriptor
    ]

    // MARK: - Egenskaper

    nonisolated private let store = CNContactStore()
    private let storage = Storage.storage()

    var authorizationStatus: CNAuthorizationStatus {
        CNContactStore.authorizationStatus(for: .contacts)
    }

    // MARK: - requestAccessAndFetch

    func requestAccessAndFetch() async throws -> [ImportableContact] {
        let status = CNContactStore.authorizationStatus(for: .contacts)
        switch status {
        case .authorized, .limited:
            break  // .limited (iOS 18+) = partiell access, visa det vi har
        case .notDetermined:
            let granted = try await store.requestAccess(for: .contacts)
            guard granted else { return [] }
        case .denied, .restricted:
            throw ContactImportError.accessDenied
        @unknown default:
            throw ContactImportError.accessDenied
        }

        // enumerateContacts är synkront — kör på bakgrundstråd
        // store och keysToFetch är nonisolated, kan nås direkt från Task.detached
        let store = self.store
        return try await Task.detached(priority: .userInitiated) {
            let request = CNContactFetchRequest(keysToFetch: ContactImportService.keysToFetch)
            request.sortOrder = .userDefault
            var contacts: [ImportableContact] = []
            try store.enumerateContacts(with: request) { contact, _ in
                let givenName = contact.givenName
                let familyName = contact.familyName
                let fullName = "\(givenName) \(familyName)".trimmingCharacters(in: .whitespaces)
                guard !fullName.isEmpty else { return }  // Hoppa över kontakter utan namn

                let phones = contact.phoneNumbers.map { $0.value.stringValue }
                let emails = contact.emailAddresses.map { $0.value as String }
                let address = contact.postalAddresses.first?.value
                let hasAddress = address != nil

                contacts.append(ImportableContact(
                    id: contact.identifier,
                    givenName: givenName,
                    familyName: familyName,
                    fullName: fullName,
                    phoneNumbers: phones,
                    emailAddresses: emails,
                    postalCity: address?.city ?? "",
                    postalCountry: address?.country ?? "",
                    thumbnailImageData: contact.thumbnailImageData,
                    hasAddress: hasAddress
                ))
            }
            return contacts
        }.value
    }

    // MARK: - uploadContactPhoto

    func uploadContactPhoto(uid: String, friendId: String, imageData: Data) async throws -> String {
        let ref = storage.reference().child("users/\(uid)/friends/\(friendId).jpg")
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        _ = try await ref.putDataAsync(imageData, metadata: metadata)
        let url = try await ref.downloadURL()
        return url.absoluteString
    }

    // MARK: - saveImportedContacts

    func saveImportedContacts(uid: String, contacts: [ImportableContact], friendService: FriendService) async throws -> [Friend] {
        var savedFriends: [Friend] = []

        for contact in contacts {
            // Skapa Friend utan photoURL först (för att få document ID)
            let friend = Friend(
                displayName: contact.fullName,
                photoURL: nil,
                city: contact.hasAddress && !contact.postalCity.isEmpty
                    ? "\(contact.postalCity), \(contact.postalCountry)"
                    : "Okänd plats",
                cityLatitude: nil,  // Koordinater sätts av AI-gissning i plan 03-02
                cityLongitude: nil,
                isFavorite: false,
                isDemo: false
            )

            try await friendService.addFriend(uid: uid, friend: friend)

            // Profilbilden uppdateras i plan 03-02 där import-reviewflödet hanteras.
            // I denna plan sparas vännen utan bild — bilden kan läggas till senare.

            savedFriends.append(friend)
        }

        return savedFriends
    }
}
