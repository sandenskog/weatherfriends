import Foundation
import MapKit
import CoreLocation

@Observable
@MainActor
class LocationService: NSObject {

    // MARK: - Public Properties

    var suggestions: [MKLocalSearchCompletion] = []
    var queryFragment: String = "" {
        didSet {
            completer.queryFragment = queryFragment
        }
    }

    // MARK: - Private

    private let completer: MKLocalSearchCompleter
    private let locationManager: CLLocationManager

    // MARK: - Init

    override init() {
        completer = MKLocalSearchCompleter()
        locationManager = CLLocationManager()
        super.init()
        completer.resultTypes = .address
        completer.delegate = self
    }

    // MARK: - Resolve selected completion to coordinates

    /// Löser upp en MKLocalSearchCompletion till ett CLPlacemark med koordinater
    func resolveLocation(_ completion: MKLocalSearchCompletion) async -> CLPlacemark? {
        let request = MKLocalSearch.Request(completion: completion)
        let search = MKLocalSearch(request: request)
        do {
            let response = try await search.start()
            return response.mapItems.first?.placemark
        } catch {
            return nil
        }
    }

    // MARK: - GPS current location

    /// Begär aktuell GPS-position och returnerar ett CLPlacemark
    /// Returnerar nil om användaren nekar tillstånd eller om fel uppstår
    func requestCurrentLocation() async -> CLPlacemark? {
        // Kontrollera tillstånd
        let status = locationManager.authorizationStatus
        if status == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
            // Ge systemet tid att visa dialogrutan
            try? await Task.sleep(nanoseconds: 1_000_000_000)
        }

        let currentStatus = locationManager.authorizationStatus
        guard currentStatus == .authorizedWhenInUse || currentStatus == .authorizedAlways else {
            return nil
        }

        // Hämta position med iOS 17+ CLLocationUpdate.liveUpdates()
        do {
            for try await update in CLLocationUpdate.liveUpdates() {
                guard let location = update.location else { continue }
                // Vi har fått en position — reverse geocoda och returnera
                let geocoder = CLGeocoder()
                let placemarks = try? await geocoder.reverseGeocodeLocation(location)
                return placemarks?.first
            }
        } catch {
            return nil
        }
        return nil
    }
}

// MARK: - MKLocalSearchCompleterDelegate

extension LocationService: MKLocalSearchCompleterDelegate {
    nonisolated func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        let results = completer.results

        // Prioritera: exakt titel-match och resultat med landsnamn i subtitle (= stad/kommun)
        // framför småorter med kommun/län i subtitle
        let sorted = results.sorted { a, b in
            let aScore = Self.locationScore(a, query: completer.queryFragment)
            let bScore = Self.locationScore(b, query: completer.queryFragment)
            return aScore > bScore
        }

        Task { @MainActor in
            self.suggestions = sorted
        }
    }

    /// Ger högre poäng till städer/kommuner framför stadsdelar och småorter
    private nonisolated static func locationScore(_ result: MKLocalSearchCompletion, query: String) -> Int {
        var score = 0
        let title = result.title.lowercased()
        let subtitle = result.subtitle.lowercased()
        let q = query.lowercased().trimmingCharacters(in: .whitespaces)

        // Exakt match på titel → högst prioritet
        if title == q { score += 100 }
        // Titel börjar med sökfrågan
        else if title.hasPrefix(q) { score += 50 }

        // Subtitle är ett land (kort, utan komma) → troligen en stad
        if !subtitle.isEmpty && !subtitle.contains(",") {
            score += 30
        }

        // Subtitle är tom → toplevel plats
        if subtitle.isEmpty { score += 20 }

        // Straffa resultat där titeln har samma namn men subtitle tyder på en stadsdel
        // (subtitle innehåller komma = "Nynäshamn, Sweden" = stad i kommun)
        if subtitle.contains(",") { score += 10 }

        return score
    }

    nonisolated func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        Task { @MainActor in
            self.suggestions = []
        }
    }
}
