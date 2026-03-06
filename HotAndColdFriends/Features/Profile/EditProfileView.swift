import SwiftUI
import PhotosUI

struct EditProfileView: View {
    let uid: String
    @Environment(AuthManager.self) private var authManager
    @Environment(UserService.self) private var userService
    @Environment(\.dismiss) private var dismiss

    @State private var viewModel = ProfileViewModel()
    @State private var locationService = LocationService()

    // Redigeringsfält
    @State private var displayName: String = ""
    @State private var selectedCity: String = ""
    @State private var selectedCityLatitude: Double?
    @State private var selectedCityLongitude: Double?
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var profileImage: UIImage?
    @State private var isSaving: Bool = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                // Profilbild
                Section {
                    HStack {
                        Spacer()
                        VStack(spacing: 12) {
                            profileImageView
                                .frame(width: 90, height: 90)

                            PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                                Text("Byt bild")
                                    .font(.subheadline.weight(.medium))
                                    .foregroundStyle(.blue)
                            }
                        }
                        Spacer()
                    }
                    .padding(.vertical, 8)
                    .listRowBackground(Color.clear)
                }

                // Namn
                Section("Namn") {
                    TextField("Ditt namn", text: $displayName)
                        .autocorrectionDisabled()
                }

                // Stad/land
                Section("Stad") {
                    // Sökfält
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

                    // GPS-knapp
                    Button {
                        Task { await fetchCurrentLocation() }
                    } label: {
                        Label("Uppdatera plats", systemImage: "location.fill")
                            .font(.subheadline)
                    }

                    // Vald stad
                    if !selectedCity.isEmpty {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                            Text(selectedCity)
                                .font(.subheadline)
                        }
                    }
                }

                // Autocomplete-förslag
                if !locationService.suggestions.isEmpty && !locationService.queryFragment.isEmpty {
                    Section("Förslag") {
                        ForEach(locationService.suggestions.prefix(6), id: \.self) { suggestion in
                            Button {
                                Task { await selectSuggestion(suggestion) }
                            } label: {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(suggestion.title)
                                        .foregroundStyle(.primary)
                                    if !suggestion.subtitle.isEmpty {
                                        Text(suggestion.subtitle)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Redigera profil")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Avbryt") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Spara") {
                        Task { await saveProfile() }
                    }
                    .disabled(isSaving || displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .overlay {
                        if isSaving { ProgressView().scaleEffect(0.7) }
                    }
                }
            }
            .alert("Fel", isPresented: .constant(errorMessage != nil)) {
                Button("OK") { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
            }
        }
        .task {
            await loadCurrentProfile()
        }
        .onChange(of: selectedPhotoItem) { _, newItem in
            Task {
                guard let item = newItem,
                      let data = try? await item.loadTransferable(type: Data.self),
                      let image = UIImage(data: data) else { return }
                profileImage = image
            }
        }
    }

    // MARK: - Profile Image View

    @ViewBuilder
    private var profileImageView: some View {
        if let image = profileImage {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: 90, height: 90)
                .clipShape(Circle())
        } else {
            AvatarView(
                displayName: displayName,
                temperatureCelsius: nil,
                size: 90,
                photoURL: viewModel.user?.profileImageURL?.absoluteString
            )
        }
    }

    // MARK: - Actions

    private func loadCurrentProfile() async {
        await viewModel.loadProfile(uid: uid, userService: userService)
        if let user = viewModel.user {
            displayName = user.displayName
            selectedCity = user.city
            selectedCityLatitude = user.cityLatitude
            selectedCityLongitude = user.cityLongitude
        }
    }

    private func saveProfile() async {
        isSaving = true
        errorMessage = nil
        defer { isSaving = false }

        let photoData: Data?
        if let image = profileImage {
            photoData = image.jpegData(compressionQuality: 0.8)
        } else {
            photoData = nil
        }

        do {
            try await viewModel.updateProfile(
                uid: uid,
                displayName: displayName,
                city: selectedCity,
                lat: selectedCityLatitude,
                lon: selectedCityLongitude,
                photoData: photoData,
                userService: userService
            )

            // Uppdatera AuthManager om det är egen profil
            if authManager.currentUser?.id == uid {
                authManager.currentUser = viewModel.user
            }

            dismiss()
        } catch {
            errorMessage = "Kunde inte spara: \(error.localizedDescription)"
        }
    }

    private func selectSuggestion(_ suggestion: MKLocalSearchCompletion) async {
        if let placemark = await locationService.resolveLocation(suggestion) {
            selectedCityLatitude = placemark.location?.coordinate.latitude
            selectedCityLongitude = placemark.location?.coordinate.longitude
            let country = placemark.country ?? suggestion.subtitle.components(separatedBy: ",").last?.trimmingCharacters(in: .whitespaces) ?? ""
            selectedCity = country.isEmpty ? suggestion.title : "\(suggestion.title), \(country)"
        } else {
            selectedCity = suggestion.title
        }
        locationService.queryFragment = ""
    }

    private func fetchCurrentLocation() async {
        if let placemark = await locationService.requestCurrentLocation() {
            let city = placemark.locality ?? placemark.administrativeArea ?? ""
            let country = placemark.country ?? ""
            selectedCity = [city, country].filter { !$0.isEmpty }.joined(separator: ", ")
            selectedCityLatitude = placemark.location?.coordinate.latitude
            selectedCityLongitude = placemark.location?.coordinate.longitude
            locationService.queryFragment = ""
        }
    }
}

// MARK: - Import MapKit for MKLocalSearchCompletion

import MapKit

#Preview {
    EditProfileView(uid: "preview-uid")
        .environment(AuthManager())
        .environment(UserService())
}
