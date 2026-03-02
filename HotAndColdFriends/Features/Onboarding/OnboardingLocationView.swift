import SwiftUI
import MapKit

struct OnboardingLocationView: View {
    @Binding var selectedCity: String
    @Binding var selectedCityLatitude: Double?
    @Binding var selectedCityLongitude: Double?
    @State private var locationService = LocationService()
    @State private var isLoadingGPS: Bool = false

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            VStack(spacing: 16) {
                Image(systemName: "location.circle")
                    .font(.system(size: 64))
                    .foregroundStyle(.secondary)

                Text("Var bor du?")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("Vi använder din stad för att hämta väder hos dina vänner.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            VStack(spacing: 8) {
                // Sökfält
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                    TextField("Sök stad eller ort...", text: $locationService.queryFragment)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)

                    if !locationService.queryFragment.isEmpty {
                        Button {
                            locationService.queryFragment = ""
                            selectedCity = ""
                            selectedCityLatitude = nil
                            selectedCityLongitude = nil
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

                // GPS-knapp
                Button {
                    Task { await fetchCurrentLocation() }
                } label: {
                    HStack {
                        if isLoadingGPS {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "location.fill")
                        }
                        Text(isLoadingGPS ? "Hämtar plats..." : "Använd min plats")
                            .font(.subheadline.weight(.medium))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .padding(.horizontal)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(isLoadingGPS)
                .padding(.horizontal)
            }

            // Autocomplete-förslag
            if !locationService.suggestions.isEmpty && !locationService.queryFragment.isEmpty {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        ForEach(locationService.suggestions.prefix(8), id: \.self) { suggestion in
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
                }
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(color: .black.opacity(0.08), radius: 8, y: 4)
                .padding(.horizontal)
                .frame(maxHeight: 220)
            }

            // Vald stad-visning
            if !selectedCity.isEmpty {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    Text(selectedCity)
                        .font(.subheadline.weight(.medium))
                    Spacer()
                }
                .padding()
                .background(Color.green.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal)
            }

            Spacer()
        }
    }

    // MARK: - Actions

    private func selectSuggestion(_ suggestion: MKLocalSearchCompletion) async {
        if let placemark = await locationService.resolveLocation(suggestion) {
            selectedCityLatitude = placemark.location?.coordinate.latitude
            selectedCityLongitude = placemark.location?.coordinate.longitude

            // Bygg stadsnamn från suggestion title + country
            let country = placemark.country ?? suggestion.subtitle.components(separatedBy: ",").last?.trimmingCharacters(in: .whitespaces) ?? ""
            if !country.isEmpty {
                selectedCity = "\(suggestion.title), \(country)"
            } else {
                selectedCity = suggestion.title
            }
        } else {
            selectedCity = suggestion.title
        }
        locationService.queryFragment = ""
    }

    private func fetchCurrentLocation() async {
        isLoadingGPS = true
        defer { isLoadingGPS = false }

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

#Preview {
    @Previewable @State var city = ""
    @Previewable @State var lat: Double? = nil
    @Previewable @State var lon: Double? = nil
    OnboardingLocationView(selectedCity: $city, selectedCityLatitude: $lat, selectedCityLongitude: $lon)
}
