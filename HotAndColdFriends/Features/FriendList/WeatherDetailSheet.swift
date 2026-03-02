import SwiftUI
import WeatherKit

struct WeatherDetailSheet: View {
    let friendWeather: FriendWeather
    @Environment(AppWeatherService.self) private var weatherService

    @State private var hourlyForecast: [HourWeather] = []
    @State private var dailyForecast: [DayWeather] = []
    @State private var isLoading = true
    @State private var errorMessage: String?

    private static let hourFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH"
        return f
    }()

    private static let dayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "EEE"
        f.locale = Locale(identifier: "sv_SE")
        return f
    }()

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                headerSection

                if friendWeather.weather == nil {
                    Text("Väderdata kunde inte hämtas just nu.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding(.top, 20)
                } else if isLoading {
                    ProgressView("Hämtar väderdata...")
                        .padding(.top, 20)
                } else if let error = errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding()
                } else {
                    detailsSection
                    if !hourlyForecast.isEmpty {
                        hourlySection
                    }
                    if !dailyForecast.isEmpty {
                        dailySection
                    }
                }
            }
            .padding()
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .task {
            await loadDetailedWeather()
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 8) {
            profileImage
                .frame(width: 80, height: 80)
                .clipShape(Circle())

            Text(friendWeather.friend.displayName)
                .font(.title2.weight(.semibold))

            Text(friendWeather.friend.city)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            HStack(alignment: .center, spacing: 12) {
                Text(friendWeather.temperatureFormatted)
                    .font(.system(size: 52, weight: .thin))
                    .foregroundStyle(
                        friendWeather.temperatureCelsius.map { Color.temperatureColor(celsius: $0) } ?? .secondary
                    )

                Image(systemName: friendWeather.symbolName)
                    .font(.system(size: 48))
                    .foregroundStyle(
                        friendWeather.temperatureCelsius.map { Color.temperatureColor(celsius: $0) } ?? .secondary
                    )
            }

            Text(friendWeather.conditionDescription)
                .font(.body)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Details

    private var detailsSection: some View {
        VStack(spacing: 0) {
            detailRow(
                icon: "thermometer.medium",
                label: "Känns som",
                value: feelsLikeFormatted
            )
            Divider()
            detailRow(
                icon: "wind",
                label: "Vind",
                value: windFormatted
            )
            Divider()
            detailRow(
                icon: "humidity",
                label: "Luftfuktighet",
                value: friendWeather.humidity.map { String(format: "%.0f%%", $0) } ?? "—"
            )
            Divider()
            detailRow(
                icon: "sun.max",
                label: "UV-index",
                value: uvIndexValue
            )
        }
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func detailRow(icon: String, label: String, value: String) -> some View {
        HStack {
            Image(systemName: icon)
                .frame(width: 24)
                .foregroundStyle(.secondary)
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: - Hourly Forecast

    private var hourlySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Timprognos")
                .font(.headline)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(hourlyForecast.prefix(12), id: \.date) { hour in
                        VStack(spacing: 6) {
                            Text(Self.hourFormatter.string(from: hour.date))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Image(systemName: hour.symbolName)
                                .font(.body)
                            Text(hour.temperature.converted(to: .celsius)
                                .formatted(.measurement(width: .narrow)))
                                .font(.caption.weight(.medium))
                        }
                        .frame(minWidth: 44)
                    }
                }
                .padding(.horizontal, 4)
            }
            .padding(.vertical, 8)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    // MARK: - Daily Forecast

    private var dailySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("5-dagarsprognos")
                .font(.headline)

            VStack(spacing: 0) {
                ForEach(Array(dailyForecast.prefix(5).enumerated()), id: \.offset) { idx, day in
                    HStack {
                        Text(idx == 0 ? "Idag" : Self.dayFormatter.string(from: day.date).capitalized)
                            .frame(width: 60, alignment: .leading)
                        Image(systemName: day.symbolName)
                            .frame(width: 24)
                        Spacer()
                        Text(day.lowTemperature.converted(to: .celsius)
                            .formatted(.measurement(width: .narrow)))
                            .foregroundStyle(.secondary)
                            .frame(width: 40, alignment: .trailing)
                        Text("–")
                            .foregroundStyle(.secondary)
                        Text(day.highTemperature.converted(to: .celsius)
                            .formatted(.measurement(width: .narrow)))
                            .frame(width: 40, alignment: .leading)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    if idx < min(4, dailyForecast.count - 1) {
                        Divider()
                    }
                }
            }
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    // MARK: - Profile Image

    @ViewBuilder
    private var profileImage: some View {
        if let urlString = friendWeather.friend.photoURL, let url = URL(string: urlString) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().scaledToFill()
                default:
                    initialsCircle(size: 80)
                }
            }
        } else {
            initialsCircle(size: 80)
        }
    }

    private func initialsCircle(size: CGFloat) -> some View {
        ZStack {
            Circle().fill(Color(.systemGray5))
            Text(initials(from: friendWeather.friend.displayName))
                .font(.title2.weight(.semibold))
                .foregroundStyle(.secondary)
        }
        .frame(width: size, height: size)
    }

    private func initials(from name: String) -> String {
        let parts = name.split(separator: " ")
        let letters = parts.prefix(2).compactMap { $0.first.map { String($0) } }
        return letters.joined().uppercased()
    }

    // MARK: - Data Loading

    private func loadDetailedWeather() async {
        guard let lat = friendWeather.friend.cityLatitude,
              let lon = friendWeather.friend.cityLongitude else {
            isLoading = false
            errorMessage = "Koordinater saknas för denna vän."
            return
        }

        do {
            let (_, hourly, daily) = try await weatherService.detailedWeather(latitude: lat, longitude: lon)
            hourlyForecast = Array(hourly)
            dailyForecast = daily.map { Array($0) } ?? []
            isLoading = false
        } catch {
            isLoading = false
            errorMessage = "Kunde inte hämta detaljerad väderdata."
        }
    }

    // MARK: - Computed values from current weather

    private var feelsLikeFormatted: String {
        guard let weather = friendWeather.weather else { return "—" }
        let celsius = weather.apparentTemperature.converted(to: .celsius)
        return celsius.formatted(.measurement(width: .narrow))
    }

    private var windFormatted: String {
        guard let weather = friendWeather.weather,
              let speed = friendWeather.windSpeed else { return "—" }
        let direction = weather.wind.compassDirection.abbreviation
        return String(format: "%.1f m/s %@", speed, direction)
    }

    private var uvIndexValue: String {
        guard let weather = friendWeather.weather else { return "—" }
        let uv = weather.uvIndex
        return "\(uv.value) \(uv.category.description)"
    }
}
