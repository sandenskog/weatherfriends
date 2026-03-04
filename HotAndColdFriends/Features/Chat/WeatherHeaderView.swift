import SwiftUI
import WeatherKit

struct WeatherHeaderView: View {
    let participants: [AppUser]
    @Environment(AppWeatherService.self) private var weatherService

    @State private var weatherData: [String: ParticipantWeather] = [:]

    var body: some View {
        if participants.isEmpty {
            EmptyView()
        } else if participants.count == 1, let user = participants.first {
            singleParticipantHeader(user: user)
        } else {
            groupParticipantsHeader
        }
    }

    // MARK: - 1-till-1 header

    @ViewBuilder
    private func singleParticipantHeader(user: AppUser) -> some View {
        let data = weatherData[user.id ?? ""]
        HStack(spacing: 12) {
            Spacer()
            if let symbol = data?.symbolName {
                Image(systemName: symbol)
                    .font(.title2)
                    .foregroundStyle(tempColor(celsius: data?.celsius))
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(user.city)
                    .font(.subheadline.weight(.medium))
                if let celsius = data?.celsius {
                    Text("\(Int(celsius.rounded()))°")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(TemperatureZone(celsius: celsius).color)
                } else {
                    Text("Laddar...")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
        }
        .padding(.vertical, 8)
        .padding(.horizontal)
        .background(Color(.systemGroupedBackground))
        .task(id: user.id) {
            await loadWeather(for: user)
        }
    }

    // MARK: - Grupp-header

    private var groupParticipantsHeader: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(participants) { user in
                    groupWeatherCard(user: user)
                        .task(id: user.id) {
                            await loadWeather(for: user)
                        }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .background(Color(.systemGroupedBackground))
    }

    @ViewBuilder
    private func groupWeatherCard(user: AppUser) -> some View {
        let data = weatherData[user.id ?? ""]
        VStack(spacing: 4) {
            Text(user.displayName)
                .font(.caption2.weight(.semibold))
                .lineLimit(1)
            if let symbol = data?.symbolName {
                Image(systemName: symbol)
                    .font(.body)
                    .foregroundStyle(tempColor(celsius: data?.celsius))
            } else {
                Image(systemName: "cloud")
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
            Text(user.city)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
            if let celsius = data?.celsius {
                Text("\(Int(celsius.rounded()))°")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(TemperatureZone(celsius: celsius).color)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
    }

    // MARK: - Helpers

    private func loadWeather(for user: AppUser) async {
        guard let lat = user.cityLatitude, let lon = user.cityLongitude else { return }
        guard let weather = try? await weatherService.currentWeather(latitude: lat, longitude: lon) else { return }
        let uid = user.id ?? UUID().uuidString
        weatherData[uid] = ParticipantWeather(
            symbolName: weather.symbolName,
            celsius: weather.temperature.converted(to: .celsius).value
        )
    }

    private func tempColor(celsius: Double?) -> Color {
        guard let c = celsius else { return .secondary }
        return TemperatureZone(celsius: c).color
    }
}

// MARK: - Supporting type

private struct ParticipantWeather {
    let symbolName: String
    let celsius: Double
}
