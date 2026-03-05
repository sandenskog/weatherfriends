import SwiftUI

// MARK: - WeatherStickerView

struct WeatherStickerView: View {
    let weatherData: WeatherStickerData

    private var zone: TemperatureZone {
        TemperatureZone(celsius: weatherData.temperatureCelsius)
    }

    var body: some View {
        let celsius = weatherData.temperatureCelsius

        VStack(spacing: 6) {
            WeatherIconMapper.icon(for: weatherData.conditionSymbol, size: 36)

            Text(weatherData.city)
                .font(.bubbleCaption)
                .foregroundStyle(Color.bubbleTextSecondary)
                .lineLimit(1)

            Text("\(Int(celsius.rounded()))°")
                .font(.bubbleTemperature)
                .foregroundStyle(zone.gradient)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .frame(maxWidth: 200)
        .background(
            zone.gradient.opacity(0.12)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(
                    LinearGradient(
                        colors: [zone.color.opacity(0.5), zone.color.opacity(0.2)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - WeatherStickerPickerView

struct WeatherStickerPickerView: View {
    let currentUser: AppUser?
    let otherUsers: [AppUser]
    let weatherService: AppWeatherService
    let onSelect: (WeatherStickerData) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var stickerOptions: [StickerOption] = []
    @State private var isLoading = true

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView("Hämtar väder...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if stickerOptions.isEmpty {
                    ContentUnavailableView(
                        "Inga väderdata",
                        systemImage: "cloud.slash",
                        description: Text("Ingen platsinformation tillgänglig")
                    )
                } else {
                    pickerList
                }
            }
            .navigationTitle("Välj väder-sticker")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Avbryt") { dismiss() }
                }
            }
        }
        .task {
            await loadStickerOptions()
        }
    }

    private var pickerList: some View {
        List(stickerOptions) { option in
            Button {
                onSelect(option.stickerData)
            } label: {
                HStack(spacing: 16) {
                    WeatherStickerView(weatherData: option.stickerData)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(option.label)
                            .font(.headline)
                        Text(option.stickerData.city)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundStyle(.secondary)
                        .font(.caption)
                }
                .padding(.vertical, 4)
            }
            .buttonStyle(.plain)
        }
        .listStyle(.plain)
    }

    private func loadStickerOptions() async {
        var options: [StickerOption] = []

        // Mitt väder
        if let user = currentUser,
           let lat = user.cityLatitude,
           let lon = user.cityLongitude,
           let weather = try? await weatherService.currentWeather(latitude: lat, longitude: lon) {
            let data = WeatherStickerData(
                city: user.city,
                countryCode: "",
                temperatureCelsius: weather.temperature.converted(to: .celsius).value,
                conditionSymbol: weather.symbolName,
                ownerUid: user.id ?? ""
            )
            options.append(StickerOption(label: "Mitt väder", stickerData: data))
        }

        // Andras väder
        for user in otherUsers {
            guard let lat = user.cityLatitude, let lon = user.cityLongitude else { continue }
            guard let weather = try? await weatherService.currentWeather(latitude: lat, longitude: lon) else { continue }
            let data = WeatherStickerData(
                city: user.city,
                countryCode: "",
                temperatureCelsius: weather.temperature.converted(to: .celsius).value,
                conditionSymbol: weather.symbolName,
                ownerUid: user.id ?? ""
            )
            options.append(StickerOption(label: "\(user.displayName)s väder", stickerData: data))
        }

        stickerOptions = options
        isLoading = false
    }
}

// MARK: - Supporting type

private struct StickerOption: Identifiable {
    let id = UUID()
    let label: String
    let stickerData: WeatherStickerData
}
