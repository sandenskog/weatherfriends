import SwiftUI
import MapKit

struct FriendMapView: View {
    let friendWeathers: [FriendWeather]
    @State private var selectedFriendWeather: FriendWeather?
    @State private var position: MapCameraPosition = .automatic
    @State private var viewModel = FriendMapViewModel()
    @Environment(AppWeatherService.self) private var weatherService

    private var mappableFriends: [FriendWeather] {
        friendWeathers.filter {
            $0.friend.cityLatitude != nil && $0.friend.cityLongitude != nil
        }
    }

    var body: some View {
        Group {
            if mappableFriends.isEmpty {
                ContentUnavailableView(
                    "Inga vänner på kartan",
                    systemImage: "map",
                    description: Text("Vänner med platsdata visas här som nålar.")
                )
            } else {
                Map(position: $position) {
                    ForEach(mappableFriends) { fw in
                        Annotation("", coordinate: CLLocationCoordinate2D(
                            latitude: fw.friend.cityLatitude!,
                            longitude: fw.friend.cityLongitude!
                        )) {
                            FriendMapPin(
                                friendWeather: fw,
                                isFavorite: fw.friend.isFavorite,
                                cachedImage: viewModel.loadedImages[fw.friend.photoURL ?? ""]
                            )
                            .onTapGesture { selectedFriendWeather = fw }
                        }
                    }
                }
            }
        }
        .sheet(item: $selectedFriendWeather) { fw in
            WeatherDetailSheet(friendWeather: fw)
                .environment(weatherService)
        }
        .task {
            await viewModel.preloadImages(for: friendWeathers)
        }
    }
}

// MARK: - FriendMapPin

private struct FriendMapPin: View {
    let friendWeather: FriendWeather
    let isFavorite: Bool
    let cachedImage: UIImage?

    private var pinSize: CGFloat { isFavorite ? 48 : 36 }
    private var tempColor: Color {
        friendWeather.temperatureCelsius.map { TemperatureZone(celsius: $0).color } ?? .secondary
    }

    var body: some View {
        VStack(spacing: 2) {
            profileCircle
                .frame(width: pinSize, height: pinSize)
                .clipShape(Circle())
                .overlay(Circle().stroke(tempColor, lineWidth: isFavorite ? 3 : 2))
            Text(friendWeather.temperatureFormatted)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(tempColor)
                .padding(.horizontal, 4)
                .background(.ultraThinMaterial, in: Capsule())
        }
    }

    @ViewBuilder
    private var profileCircle: some View {
        if let image = cachedImage {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
        } else {
            ZStack {
                Circle().fill(Color(.systemGray5))
                Text(initials(from: friendWeather.friend.displayName))
                    .font(isFavorite ? .caption.weight(.semibold) : .caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func initials(from name: String) -> String {
        let parts = name.split(separator: " ")
        let letters = parts.prefix(2).compactMap { $0.first.map { String($0) } }
        return letters.joined().uppercased()
    }
}
