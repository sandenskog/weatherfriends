import SwiftUI
import MapKit
import CoreLocation

// MARK: - ReviewItem

struct ReviewItem: Identifiable {
    let id: String  // contact.id
    let contact: ImportableContact
    var city: String
    var country: String
    var latitude: Double?
    var longitude: Double?
    var confidence: String  // "high", "medium", "low", "unknown"
    var reason: String
    var isIncluded: Bool  // Användaren kan avvisa enskilda kontakter
}

// MARK: - ImportReviewMode

enum ImportReviewMode {
    case standard(uid: String, friendService: FriendService)
    case onboarding(onPendingFriendsReady: ([PendingFriend]) -> Void)
}

// MARK: - ImportReviewView

struct ImportReviewView: View {
    let mode: ImportReviewMode
    let contacts: [ImportableContact]
    let locationGuesses: [LocationGuess]
    let contactImportService: ContactImportService
    let onCompleted: () -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(UserService.self) private var userService
    @State private var reviewItems: [ReviewItem] = []
    @State private var editingItemId: String? = nil
    @State private var locationService = LocationService()
    @State private var isSaving = false
    @State private var isLoadingReview = true
    @State private var errorMessage: String?

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Group {
                if isLoadingReview {
                    VStack(spacing: 16) {
                        ProgressView("Löser upp platser...")
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        // Sammanfattning
                        Section {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("\(reviewItems.filter { $0.isIncluded }.count) av \(reviewItems.count) kontakter valda")
                                    .font(.subheadline.weight(.medium))
                                Text("Granska platsförslagen nedan. Grönt = säkert, gult = troligt, rött = osäkert.")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 4)
                        }

                        // Kontaktlista
                        ForEach($reviewItems) { $item in
                            reviewRow(item: $item)
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Granska import")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Avbryt") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        Task { await saveAll() }
                    } label: {
                        if isSaving {
                            ProgressView()
                        } else {
                            Text("Spara")
                                .fontWeight(.semibold)
                        }
                    }
                    .disabled(reviewItems.filter { $0.isIncluded }.isEmpty || isSaving || isLoadingReview)
                }
            }
            .alert("Fel", isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) {
                Button("OK") { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
            }
        }
        .task {
            await buildReviewItems()
        }
    }

    // MARK: - Review Row

    @ViewBuilder
    private func reviewRow(item: Binding<ReviewItem>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                // Include/exclude toggle
                Button {
                    item.wrappedValue.isIncluded.toggle()
                } label: {
                    Image(systemName: item.wrappedValue.isIncluded ? "checkmark.circle.fill" : "circle")
                        .font(.title3)
                        .foregroundStyle(item.wrappedValue.isIncluded ? .blue : Color(.systemGray3))
                }

                // Profilbild eller initialer
                if let imageData = item.wrappedValue.contact.thumbnailImageData,
                   let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 36, height: 36)
                        .clipShape(Circle())
                } else {
                    ZStack {
                        Circle()
                            .fill(Color(.systemGray5))
                            .frame(width: 36, height: 36)
                        Text(initials(for: item.wrappedValue.contact.fullName))
                            .font(.caption.weight(.semibold))
                    }
                }

                // Namn och stad
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.wrappedValue.contact.fullName)
                        .font(.body)

                    HStack(spacing: 4) {
                        // Konfidens-prick
                        Circle()
                            .fill(confidenceColor(item.wrappedValue.confidence))
                            .frame(width: 8, height: 8)

                        if item.wrappedValue.city.isEmpty {
                            Text("Okänd plats")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        } else {
                            Text(item.wrappedValue.country.isEmpty
                                ? item.wrappedValue.city
                                : "\(item.wrappedValue.city), \(item.wrappedValue.country)")
                                .font(.caption)
                                .foregroundStyle(.primary)
                        }
                    }

                    // Anledning
                    Text(item.wrappedValue.reason)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                // Redigera-knapp
                Button {
                    if editingItemId == item.wrappedValue.id {
                        editingItemId = nil
                        locationService.queryFragment = ""
                    } else {
                        editingItemId = item.wrappedValue.id
                        locationService.queryFragment = ""
                    }
                } label: {
                    Image(systemName: "pencil.circle")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
            }

            // Inline stad-korrigering (visas om denna rad redigeras)
            if editingItemId == item.wrappedValue.id {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(.secondary)
                        TextField("Sök stad...", text: $locationService.queryFragment)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)

                        if !locationService.queryFragment.isEmpty {
                            Button {
                                locationService.queryFragment = ""
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .padding(10)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                    // Autocomplete-förslag
                    if !locationService.suggestions.isEmpty && !locationService.queryFragment.isEmpty {
                        ForEach(locationService.suggestions.prefix(4), id: \.self) { suggestion in
                            Button {
                                Task {
                                    await selectSuggestionForItem(suggestion, item: item)
                                }
                            } label: {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(suggestion.title)
                                        .font(.subheadline)
                                        .foregroundStyle(.primary)
                                    if !suggestion.subtitle.isEmpty {
                                        Text(suggestion.subtitle)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                .padding(.vertical, 6)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            Divider()
                        }
                    }
                }
                .padding(.leading, 60)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(.vertical, 4)
        .animation(.easeInOut(duration: 0.2), value: editingItemId)
    }

    // MARK: - Helpers

    private func confidenceColor(_ confidence: String) -> Color {
        switch confidence {
        case "high":    return .green
        case "medium":  return .yellow
        case "low":     return .orange
        default:        return .red  // "unknown"
        }
    }

    private func initials(for name: String) -> String {
        let parts = name.split(separator: " ")
        if parts.count >= 2 {
            return String((parts[0].first ?? Character(" "))).uppercased() +
                   String((parts[1].first ?? Character(" "))).uppercased()
        } else if let first = parts.first?.first {
            return String(first).uppercased()
        }
        return "?"
    }

    private func buildReviewItems() async {
        // Bygg initiala review-items från AI-gissningar
        var items: [ReviewItem] = contacts.map { contact in
            let guess = locationGuesses.first { $0.identifier == contact.id }
            return ReviewItem(
                id: contact.id,
                contact: contact,
                city: guess?.city ?? "",
                country: guess?.country ?? "",
                latitude: nil,
                longitude: nil,
                confidence: guess?.confidence ?? "unknown",
                reason: guess?.reason ?? "Ingen data tillgänglig",
                isIncluded: true
            )
        }

        // Auto-geocoda alla items med stad men utan koordinater
        for index in items.indices {
            let item = items[index]
            guard !item.city.isEmpty, item.latitude == nil else { continue }
            let addressString = item.country.isEmpty ? item.city : "\(item.city), \(item.country)"
            let geocoder = CLGeocoder()  // Ny instans per anrop (CLGeocoder tillåter inte parallella anrop)
            if let placemark = try? await geocoder.geocodeAddressString(addressString).first,
               let location = placemark.location {
                items[index].latitude = location.coordinate.latitude
                items[index].longitude = location.coordinate.longitude
            }
            // Misslyckad geocoding: koordinater förblir nil — röd prick i review-vyn, användaren kan manuellt söka
        }

        reviewItems = items
        isLoadingReview = false
    }

    private func selectSuggestionForItem(_ suggestion: MKLocalSearchCompletion, item: Binding<ReviewItem>) async {
        if let placemark = await locationService.resolveLocation(suggestion) {
            item.wrappedValue.latitude = placemark.location?.coordinate.latitude
            item.wrappedValue.longitude = placemark.location?.coordinate.longitude

            let country = placemark.country ?? suggestion.subtitle.components(separatedBy: ",").last?.trimmingCharacters(in: .whitespaces) ?? ""
            item.wrappedValue.city = suggestion.title
            item.wrappedValue.country = country
            item.wrappedValue.confidence = "high"
            item.wrappedValue.reason = "Manuellt vald"
        }
        editingItemId = nil
        locationService.queryFragment = ""
    }

    private func saveAll() async {
        isSaving = true
        defer { isSaving = false }

        let included = reviewItems.filter { $0.isIncluded }

        switch mode {
        case .standard(let uid, let friendService):
            // Befintligt Firestore-flöde (oförändrat)
            let reviewedContacts = included.map { item in
                ReviewedContact(
                    contact: item.contact,
                    city: item.city,
                    country: item.country,
                    latitude: item.latitude,
                    longitude: item.longitude,
                    confidence: item.confidence
                )
            }
            do {
                try await contactImportService.saveReviewedContacts(
                    uid: uid,
                    reviewedContacts: reviewedContacts,
                    friendService: friendService,
                    userService: userService
                )
                onCompleted()
                dismiss()
            } catch {
                errorMessage = "Kunde inte spara kontakter: \(error.localizedDescription)"
            }

        case .onboarding(let onPendingFriendsReady):
            let pendingFriends = included.map { item -> PendingFriend in
                let cityDisplay = item.city.isEmpty
                    ? "Okänd plats"
                    : (item.country.isEmpty ? item.city : "\(item.city), \(item.country)")
                return PendingFriend(
                    displayName: item.contact.fullName,
                    city: cityDisplay,
                    cityLatitude: item.latitude,
                    cityLongitude: item.longitude
                )
            }
            onPendingFriendsReady(pendingFriends)
            onCompleted()
            dismiss()
        }
    }
}
