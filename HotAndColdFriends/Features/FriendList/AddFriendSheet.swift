import SwiftUI
import MapKit

struct AddFriendSheet: View {
    let uid: String
    let friendService: FriendService
    let onAdded: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var city = ""
    @State private var latitude: Double?
    @State private var longitude: Double?
    @State private var locationService = LocationService()
    @State private var isSaving = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // MARK: - Namn
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Namn")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)

                        TextField("Vännens namn", text: $name)
                            .padding()
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    // MARK: - Stad med autocomplete
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Stad")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)

                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundStyle(.secondary)
                            TextField("Sök stad eller ort...", text: $locationService.queryFragment)
                                .autocorrectionDisabled()
                                .textInputAutocapitalization(.never)

                            if !locationService.queryFragment.isEmpty {
                                Button {
                                    locationService.queryFragment = ""
                                    city = ""
                                    latitude = nil
                                    longitude = nil
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 12))

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
                                }
                            }
                            .background(Color(.systemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .shadow(color: .black.opacity(0.08), radius: 8, y: 4)
                        }

                        // Vald stad
                        if !city.isEmpty {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                                Text(city)
                                    .font(.subheadline.weight(.medium))
                                Spacer()
                            }
                            .padding()
                            .background(Color.green.opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }

                    // MARK: - Lägg till-knapp
                    Button {
                        Task { await addFriend() }
                    } label: {
                        if isSaving {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                                .padding()
                        } else {
                            Text("Lägg till")
                                .font(.body.weight(.medium))
                                .frame(maxWidth: .infinity)
                                .padding()
                        }
                    }
                    .background(canAdd ? Color.primary : Color(.systemGray4))
                    .foregroundStyle(Color(.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .disabled(!canAdd || isSaving)
                }
                .padding()
            }
            .navigationTitle("Lägg till vän")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Avbryt") { dismiss() }
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
    }

    // MARK: - Computed

    private var canAdd: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !city.isEmpty
    }

    // MARK: - Actions

    private func addFriend() async {
        isSaving = true
        defer { isSaving = false }

        let friend = Friend(
            displayName: name.trimmingCharacters(in: .whitespacesAndNewlines),
            photoURL: nil,
            city: city,
            cityLatitude: latitude,
            cityLongitude: longitude,
            isFavorite: false,
            isDemo: false
        )

        do {
            try await friendService.addFriend(uid: uid, friend: friend)
            onAdded()
            dismiss()
        } catch {
            errorMessage = "Kunde inte lägga till vän: \(error.localizedDescription)"
        }
    }

    private func selectSuggestion(_ suggestion: MKLocalSearchCompletion) async {
        if let placemark = await locationService.resolveLocation(suggestion) {
            latitude = placemark.location?.coordinate.latitude
            longitude = placemark.location?.coordinate.longitude

            let country = placemark.country ?? suggestion.subtitle.components(separatedBy: ",").last?.trimmingCharacters(in: .whitespaces) ?? ""
            if !country.isEmpty {
                city = "\(suggestion.title), \(country)"
            } else {
                city = suggestion.title
            }
        } else {
            city = suggestion.title
        }
        locationService.queryFragment = ""
    }
}
