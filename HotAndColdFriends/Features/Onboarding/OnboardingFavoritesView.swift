import SwiftUI
import MapKit

// MARK: - Datamodell för en vän under onboarding

struct PendingFriend: Identifiable {
    let id = UUID()
    var displayName: String
    var city: String
    var cityLatitude: Double?
    var cityLongitude: Double?
}

// MARK: - OnboardingFavoritesView

struct OnboardingFavoritesView: View {
    @Binding var pendingFriends: [PendingFriend]

    @State private var newFriendName: String = ""
    @State private var newFriendCity: String = ""
    @State private var newFriendLat: Double? = nil
    @State private var newFriendLon: Double? = nil
    @State private var locationService = LocationService()
    @State private var isAddingFriend = false
    @State private var showContactImport = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Spacer(minLength: 16)

                // MARK: - Header
                VStack(spacing: 16) {
                    Image(systemName: "person.2.circle")
                        .font(.system(size: 64))
                        .foregroundStyle(.secondary)

                    Text("Lägg till vänner")
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    Text("Lägg till vänner och se deras väder direkt. De 6 första blir dina favoriter.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                // MARK: - Tillagda vänner
                VStack(spacing: 0) {
                    if pendingFriends.isEmpty {
                        Text("Inga vänner tillagda ännu")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .padding(.vertical, 24)
                    } else {
                        ForEach(Array(pendingFriends.enumerated()), id: \.element.id) { index, friend in
                            HStack(spacing: 12) {
                                // Initialer i cirkel
                                ZStack {
                                    Circle()
                                        .fill(Color(.systemGray5))
                                        .frame(width: 36, height: 36)
                                    Text(initials(for: friend.displayName))
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(.primary)
                                }

                                // Namn och stad
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(friend.displayName)
                                        .font(.body)
                                    Text(friend.city)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }

                                Spacer()

                                // Favoritstjärna för de 6 första
                                if index < 6 {
                                    Image(systemName: "star.fill")
                                        .font(.caption)
                                        .foregroundStyle(.yellow)
                                }

                                // Ta bort-knapp
                                Button {
                                    pendingFriends.remove(at: index)
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundStyle(Color(.systemGray3))
                                }
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 10)

                            if index < pendingFriends.count - 1 {
                                Divider()
                                    .padding(.horizontal)
                            }
                        }
                    }
                }
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal)

                // MARK: - Formulär för ny vän
                if isAddingFriend {
                    VStack(spacing: 16) {
                        // Namn-fält
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Namn")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                                .padding(.horizontal)

                            TextField("Vännens namn", text: $newFriendName)
                                .padding()
                                .background(Color(.systemGray6))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .padding(.horizontal)
                        }

                        // Stad-fält med autocomplete
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Stad")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                                .padding(.horizontal)

                            HStack {
                                Image(systemName: "magnifyingglass")
                                    .foregroundStyle(.secondary)
                                TextField("Sök stad eller ort...", text: $locationService.queryFragment)
                                    .autocorrectionDisabled()
                                    .textInputAutocapitalization(.never)

                                if !locationService.queryFragment.isEmpty {
                                    Button {
                                        locationService.queryFragment = ""
                                        newFriendCity = ""
                                        newFriendLat = nil
                                        newFriendLon = nil
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .padding(.horizontal)

                            // Autocomplete-förslag
                            if !locationService.suggestions.isEmpty && !locationService.queryFragment.isEmpty {
                                VStack(alignment: .leading, spacing: 0) {
                                    ForEach(locationService.suggestions.prefix(6), id: \.self) { suggestion in
                                        Button {
                                            Task { await selectSuggestion(suggestion) }
                                        } label: {
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(suggestion.title)
                                                    .font(.body)
                                                    .foregroundStyle(.primary)
                                                if !suggestion.subtitle.isEmpty {
                                                    Text(suggestion.subtitle)
                                                        .font(.caption)
                                                        .foregroundStyle(.secondary)
                                                }
                                            }
                                            .padding(.horizontal)
                                            .padding(.vertical, 10)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                        }
                                        Divider()
                                            .padding(.horizontal)
                                    }
                                }
                                .background(Color(.systemBackground))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .shadow(color: .black.opacity(0.08), radius: 8, y: 4)
                                .padding(.horizontal)
                            }

                            // Vald stad
                            if !newFriendCity.isEmpty {
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(.green)
                                    Text(newFriendCity)
                                        .font(.subheadline.weight(.medium))
                                    Spacer()
                                }
                                .padding()
                                .background(Color.green.opacity(0.08))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .padding(.horizontal)
                            }
                        }

                        // "Lägg till"-knapp
                        HStack(spacing: 12) {
                            Button {
                                resetForm()
                            } label: {
                                Text("Avbryt")
                                    .font(.body)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color(.systemGray6))
                                    .foregroundStyle(.primary)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                            }

                            Button {
                                addPendingFriend()
                            } label: {
                                Text("Lägg till")
                                    .font(.body.weight(.medium))
                                    .frame(maxWidth: .infinity)
                                    .padding()
                            }
                            .background(canAddFriend ? Color.black : Color(.systemGray4))
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.clear, lineWidth: 1)
                            )
                            .disabled(!canAddFriend)
                        }
                        .padding(.horizontal)
                    }
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                } else {
                    // MARK: - "Importera från kontakter"-knapp (primär)
                    Button {
                        showContactImport = true
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "person.crop.circle.badge.plus")
                            Text("Importera från kontakter")
                        }
                        .font(.body.weight(.medium))
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.systemGray6))
                        .foregroundStyle(.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(.horizontal)

                    // MARK: - "Lägg till en vän"-knapp (fallback)
                    Button {
                        withAnimation { isAddingFriend = true }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "plus.circle")
                            Text("Lägg till en vän")
                        }
                        .font(.body.weight(.medium))
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.systemGray6))
                        .foregroundStyle(.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(.horizontal)
                    .transition(.opacity)
                }

                Spacer(minLength: 16)
            }
        }
        .sheet(isPresented: $showContactImport) {
            ContactImportOnboardingWrapper(pendingFriends: $pendingFriends)
        }
    }

    // MARK: - Computed

    private var canAddFriend: Bool {
        !newFriendName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !newFriendCity.isEmpty
    }

    // MARK: - Actions

    private func addPendingFriend() {
        let friend = PendingFriend(
            displayName: newFriendName.trimmingCharacters(in: .whitespacesAndNewlines),
            city: newFriendCity,
            cityLatitude: newFriendLat,
            cityLongitude: newFriendLon
        )
        pendingFriends.append(friend)
        resetForm()
    }

    private func resetForm() {
        newFriendName = ""
        newFriendCity = ""
        newFriendLat = nil
        newFriendLon = nil
        locationService.queryFragment = ""
        withAnimation { isAddingFriend = false }
    }

    private func selectSuggestion(_ suggestion: MKLocalSearchCompletion) async {
        if let placemark = await locationService.resolveLocation(suggestion) {
            newFriendLat = placemark.location?.coordinate.latitude
            newFriendLon = placemark.location?.coordinate.longitude

            let country = placemark.country ?? suggestion.subtitle.components(separatedBy: ",").last?.trimmingCharacters(in: .whitespaces) ?? ""
            if !country.isEmpty {
                newFriendCity = "\(suggestion.title), \(country)"
            } else {
                newFriendCity = suggestion.title
            }
        } else {
            newFriendCity = suggestion.title
        }
        locationService.queryFragment = ""
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
}

#Preview {
    @Previewable @State var friends: [PendingFriend] = []
    OnboardingFavoritesView(pendingFriends: $friends)
}

// MARK: - ContactImportOnboardingWrapper

/// Wrapper för kontaktimport under onboarding.
/// Eftersom uid inte finns ännu (profilen skapas vid "Slutför") importeras
/// kontakter som PendingFriend istället för direkt till Firestore.
private struct ContactImportOnboardingWrapper: View {
    @Binding var pendingFriends: [PendingFriend]
    @Environment(\.dismiss) private var dismiss
    @State private var contactImportService = ContactImportService()
    @State private var contacts: [ImportableContact] = []
    @State private var selectedIds: Set<String> = []
    @State private var searchText: String = ""
    @State private var isLoading = true
    @State private var errorMessage: String?

    private var filteredContacts: [ImportableContact] {
        if searchText.isEmpty { return contacts }
        return contacts.filter { $0.fullName.localizedCaseInsensitiveContains(searchText) }
    }

    private var groupedContacts: [(String, [ImportableContact])] {
        let grouped = Dictionary(grouping: filteredContacts) { String($0.fullName.prefix(1)).uppercased() }
        return grouped.sorted { $0.key < $1.key }
    }

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView("Hämtar kontakter...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if contacts.isEmpty {
                    ContentUnavailableView(
                        "Inga kontakter",
                        systemImage: "person.crop.circle.badge.xmark",
                        description: Text("Inga kontakter hittades i din adressbok.")
                    )
                } else {
                    List {
                        ForEach(groupedContacts, id: \.0) { letter, sectionContacts in
                            Section(letter) {
                                ForEach(sectionContacts) { contact in
                                    let alreadyPending = pendingFriends.contains { $0.displayName == contact.fullName }
                                    ContactImportRow(
                                        contact: contact,
                                        isSelected: selectedIds.contains(contact.id),
                                        isAlreadyAdded: alreadyPending
                                    )
                                    .onTapGesture {
                                        guard !alreadyPending else { return }
                                        if selectedIds.contains(contact.id) {
                                            selectedIds.remove(contact.id)
                                        } else {
                                            if selectedIds.count >= 50 {
                                                errorMessage = "Du kan importera max 50 kontakter åt gången."
                                                return
                                            }
                                            selectedIds.insert(contact.id)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Importera kontakter")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Avbryt") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Lägg till (\(selectedIds.count))") {
                        addSelectedAsPending()
                    }
                    .fontWeight(.semibold)
                    .disabled(selectedIds.isEmpty)
                }
            }
            .searchable(text: $searchText, prompt: "Sök kontakter...")
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
            await loadContacts()
        }
    }

    private func loadContacts() async {
        isLoading = true
        defer { isLoading = false }
        do {
            contacts = try await contactImportService.requestAccessAndFetch()
        } catch {
            errorMessage = "Kunde inte hämta kontakter: \(error.localizedDescription)"
        }
    }

    private func addSelectedAsPending() {
        let selected = contacts.filter { selectedIds.contains($0.id) }
        for contact in selected {
            let city = contact.hasAddress && !contact.postalCity.isEmpty
                ? "\(contact.postalCity), \(contact.postalCountry)"
                : "Okänd plats"
            let pending = PendingFriend(
                displayName: contact.fullName,
                city: city,
                cityLatitude: nil,
                cityLongitude: nil
            )
            pendingFriends.append(pending)
        }
        dismiss()
    }
}
