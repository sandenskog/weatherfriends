import Contacts
import FirebaseFunctions
import Foundation
import Observation

// MARK: - Cloud Function Request/Response

struct ContactLocationRequest: Encodable {
    let contacts: [ContactPayload]
}

struct ContactPayload: Encodable {
    let identifier: String
    let givenName: String
    let familyName: String
    let phoneNumbers: [String]
    let emailAddresses: [String]
    let postalCity: String
    let postalCountry: String
}

struct LocationGuessResponse: Decodable {
    let results: [LocationGuess]
}

struct LocationGuess: Decodable, Identifiable {
    let identifier: String
    let city: String
    let country: String
    let confidence: String  // "high", "medium", "low", "unknown"
    let reason: String

    var id: String { identifier }
}

// MARK: - ReviewedContact

struct ReviewedContact {
    let contact: ImportableContact
    let city: String
    let country: String
    let latitude: Double?
    let longitude: Double?
    let confidence: String
}

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

    // MARK: - AI Location Guessing

    func guessLocations(for contacts: [ImportableContact]) async throws -> [LocationGuess] {
        let functions = Functions.functions(region: "europe-west1")
        let callable = functions.httpsCallable("guessContactLocations")

        let payload: [String: Any] = [
            "contacts": contacts.map { contact in
                [
                    "identifier": contact.id,
                    "givenName": contact.givenName,
                    "familyName": contact.familyName,
                    "phoneNumbers": contact.phoneNumbers,
                    "emailAddresses": contact.emailAddresses,
                    "postalCity": contact.postalCity,
                    "postalCountry": contact.postalCountry
                ] as [String: Any]
            }
        ]

        let result = try await callable.call(payload)

        // Parsa svaret
        guard let data = result.data as? [String: Any],
              let resultsArray = data["results"] as? [[String: Any]] else {
            return []
        }

        return resultsArray.compactMap { dict in
            guard let identifier = dict["identifier"] as? String,
                  let city = dict["city"] as? String,
                  let country = dict["country"] as? String,
                  let confidence = dict["confidence"] as? String,
                  let reason = dict["reason"] as? String else {
                return nil
            }
            return LocationGuess(
                identifier: identifier,
                city: city,
                country: country,
                confidence: confidence,
                reason: reason
            )
        }
    }

    // MARK: - saveReviewedContacts

    func saveReviewedContacts(uid: String, reviewedContacts: [ReviewedContact], friendService: FriendService, userService: UserService) async throws {
        // Rensa demo-vänner vid första riktiga import
        let existingFriends = try await friendService.fetchFriends(uid: uid)
        let hasOnlyDemoFriends = existingFriends.allSatisfy { $0.isDemo }
        if hasOnlyDemoFriends && !existingFriends.isEmpty {
            try await friendService.removeDemoFriends(uid: uid)
        }

        for reviewed in reviewedContacts {
            let resolvedAuthUid = await userService.lookupAuthUid(
                byDisplayName: reviewed.contact.fullName
            )

            let cityDisplay = reviewed.city.isEmpty
                ? "Okänd plats"
                : (reviewed.country.isEmpty ? reviewed.city : "\(reviewed.city), \(reviewed.country)")

            let friend = Friend(
                authUid: resolvedAuthUid,
                displayName: reviewed.contact.fullName,
                photoURL: nil,
                city: cityDisplay,
                cityLatitude: reviewed.latitude,
                cityLongitude: reviewed.longitude,
                isFavorite: false,
                isDemo: false
            )

            try await friendService.addFriend(uid: uid, friend: friend)
        }
    }
}
