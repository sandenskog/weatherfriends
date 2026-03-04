import SwiftUI
import Contacts

struct ContactImportView: View {
    let uid: String
    let friendService: FriendService
    let onImported: () -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(UserService.self) private var userService
    @State private var contactImportService = ContactImportService()
    @State private var contacts: [ImportableContact] = []
    @State private var selectedIds: Set<String> = []
    @State private var existingFriendNames: Set<String> = []
    @State private var searchText: String = ""
    @State private var isLoading = true
    @State private var isSaving = false
    @State private var errorMessage: String?

    // Review-flöde (03-02)
    @State private var showReview = false
    @State private var selectedContacts: [ImportableContact] = []
    @State private var locationGuesses: [LocationGuess] = []
    @State private var isGuessing = false

    // MARK: - Computed

    private var filteredContacts: [ImportableContact] {
        if searchText.isEmpty { return contacts }
        return contacts.filter {
            $0.fullName.localizedCaseInsensitiveContains(searchText)
        }
    }

    /// Gruppera kontakter alfabetiskt
    private var groupedContacts: [(String, [ImportableContact])] {
        let grouped = Dictionary(grouping: filteredContacts) { contact in
            String(contact.fullName.prefix(1)).uppercased()
        }
        return grouped.sorted { $0.key < $1.key }
    }

    private var selectedCount: Int {
        selectedIds.count
    }

    // MARK: - Body

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
                    contactList
                }
            }
            .navigationTitle("Importera kontakter")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Avbryt") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        Task { await importSelected() }
                    } label: {
                        if isGuessing {
                            HStack(spacing: 4) {
                                ProgressView()
                                    .controlSize(.small)
                                Text("Analyserar...")
                            }
                        } else if isSaving {
                            ProgressView()
                        } else {
                            Text("Importera (\(selectedCount))")
                                .fontWeight(.semibold)
                        }
                    }
                    .disabled(selectedCount == 0 || isSaving || isGuessing)
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
            .sheet(isPresented: $showReview) {
                ImportReviewView(
                    mode: .standard(uid: uid, friendService: friendService),
                    contacts: selectedContacts,
                    locationGuesses: locationGuesses,
                    contactImportService: contactImportService
                ) {
                    onImported()
                    dismiss()
                }
                .environment(userService)
            }
        }
        .task {
            await loadContacts()
        }
    }

    // MARK: - Contact List

    private var contactList: some View {
        List {
            ForEach(groupedContacts, id: \.0) { letter, contacts in
                Section(letter) {
                    ForEach(contacts) { contact in
                        let isAlreadyAdded = existingFriendNames.contains(contact.fullName)
                        ContactImportRow(
                            contact: contact,
                            isSelected: selectedIds.contains(contact.id),
                            isAlreadyAdded: isAlreadyAdded
                        )
                        .onTapGesture {
                            guard !isAlreadyAdded else { return }
                            if selectedIds.contains(contact.id) {
                                selectedIds.remove(contact.id)
                            } else {
                                // Max 50 kontakter per import-batch
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

    // MARK: - Actions

    private func loadContacts() async {
        isLoading = true
        defer { isLoading = false }

        do {
            // Hämta befintliga vänner för dubblettdetektering
            let existingFriends = try await friendService.fetchFriends(uid: uid)
            existingFriendNames = Set(existingFriends.map { $0.displayName })

            // Hämta kontakter från adressboken
            contacts = try await contactImportService.requestAccessAndFetch()
        } catch ContactImportError.accessDenied {
            errorMessage = ContactImportError.accessDenied.errorDescription
        } catch {
            errorMessage = "Kunde inte hämta kontakter: \(error.localizedDescription)"
        }
    }

    private func importSelected() async {
        isGuessing = true
        defer { isGuessing = false }

        selectedContacts = contacts.filter { selectedIds.contains($0.id) }

        do {
            // Kör AI-platsgissning via Cloud Function
            locationGuesses = try await contactImportService.guessLocations(for: selectedContacts)
            showReview = true
        } catch {
            // Vid CF-fel: visa review ändå men utan AI-gissningar
            locationGuesses = []
            showReview = true
        }
    }
}
