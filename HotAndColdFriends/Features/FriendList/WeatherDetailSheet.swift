import SwiftUI
import WeatherKit

// MARK: - WeatherDetailSheet

/// Full-screen sheet showing a friend's detailed weather.
/// The friend's weather sky fills the background; details float on a glass panel.
struct WeatherDetailSheet: View {
    let friendWeather: FriendWeather
    @Environment(AppWeatherService.self) private var weatherService
    @Environment(\.dismiss) private var dismiss

    @State private var hourlyForecast: [HourWeather] = []
    @State private var dailyForecast: [DayWeather] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var showFriendProfile = false
    @State private var shareTarget: FriendWeather?

    private var skyMood: SkyMood {
        let isDaytime = friendWeather.weather?.isDaylight ?? true
        return SkyMood.from(symbolName: friendWeather.symbolName, isDaytime: isDaytime)
    }

    private var zone: TemperatureZone {
        TemperatureZone(celsius: friendWeather.temperatureCelsius ?? 15)
    }

    private static let hourFormatter: DateFormatter = {
        let f = DateFormatter(); f.dateFormat = "HH"; return f
    }()

    private static let dayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "EEE"
        f.locale = Locale(identifier: "sv_SE")
        return f
    }()

    // MARK: - Body

    var body: some View {
        ZStack(alignment: .top) {
            // Friend's sky fills entire sheet
            AtmosphereSkyBackground(mood: skyMood)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Floating hero on sky
                heroSection
                    .padding(.top, 56)
                    .padding(.horizontal, 20)

                Spacer()

                // Glass panel with forecast
                glassPanel
                    .ignoresSafeArea(edges: .bottom)
            }

            // Nav buttons on sky
            navButtons
                .padding(.top, 12)
                .padding(.horizontal, 20)
        }
        .ignoresSafeArea()
        .sheet(isPresented: $showFriendProfile) {
            FriendProfileView(friend: friendWeather.friend)
        }
        .sheet(item: $shareTarget) { fw in
            WeatherCardPreviewSheet(friendWeather: fw)
        }
        .task { await loadDetailedWeather() }
    }

    // MARK: - Nav Buttons

    private var navButtons: some View {
        HStack {
            Button { dismiss() } label: {
                Image(systemName: "chevron.down")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.atmosphereTextOnSky)
                    .frame(width: 36, height: 36)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
            }
            Spacer()
            Button { shareTarget = friendWeather } label: {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.atmosphereTextOnSky)
                    .frame(width: 36, height: 36)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
            }
        }
    }

    // MARK: - Hero Section

    private var heroSection: some View {
        VStack(spacing: 8) {
            // Tappable profile
            Button { showFriendProfile = true } label: {
                VStack(spacing: 8) {
                    TemperatureRingAvatar(
                        photoURL: friendWeather.friend.photoURL,
                        displayName: friendWeather.friend.displayName,
                        temperatureCelsius: friendWeather.temperatureCelsius,
                        size: 64
                    )

                    Text(friendWeather.friend.displayName)
                        .font(.atmosphereCity)
                        .foregroundStyle(Color.atmosphereTextOnSky)
                        .shadow(radius: 3)

                    Text(friendWeather.friend.city)
                        .font(.atmosphereCondition)
                        .foregroundStyle(Color.atmosphereTextOnSkySecondary)
                        .shadow(radius: 2)
                }
            }
            .buttonStyle(.plain)

            // Big temperature
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Text(friendWeather.temperatureFormatted)
                    .font(.atmosphereDisplayTemp)
                    .foregroundStyle(Color.atmosphereTextOnSky)
                    .shadow(radius: 6)

                Image(systemName: friendWeather.symbolName)
                    .symbolRenderingMode(.multicolor)
                    .font(.system(size: 36))
                    .shadow(radius: 4)
            }

            Text(friendWeather.conditionDescription)
                .font(.atmosphereCondition)
                .foregroundStyle(Color.atmosphereTextOnSkySecondary)
                .shadow(radius: 2)

            // Hi/Lo pills
            if let weather = friendWeather.weather {
                HStack(spacing: 12) {
                    weatherPill(
                        icon: "arrow.up",
                        value: weather.apparentTemperature.converted(to: .celsius).formatted(
                            .measurement(width: .narrow, usage: .asProvided, numberFormatStyle: .number.precision(.fractionLength(0)))
                        )
                    )
                    weatherPill(
                        icon: "wind",
                        value: String(format: "%.0f m/s", weather.wind.speed.converted(to: .metersPerSecond).value)
                    )
                    weatherPill(
                        icon: "humidity",
                        value: String(format: "%.0f%%", weather.humidity * 100)
                    )
                }
            }
        }
    }

    private func weatherPill(icon: String, value: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .medium))
            Text(value)
                .font(.system(size: 12, weight: .medium, design: .rounded))
        }
        .foregroundStyle(Color.atmosphereTextOnSky)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
    }

    // MARK: - Glass Panel

    private var glassPanel: some View {
        VStack(spacing: 0) {
            // Drag indicator
            Capsule()
                .fill(Color.white.opacity(0.35))
                .frame(width: 36, height: 4)
                .padding(.top, 12)
                .padding(.bottom, 16)

            if isLoading {
                ProgressView("Hämtar prognos...")
                    .padding()
                Spacer()
            } else if let error = errorMessage {
                Text(error)
                    .font(.atmosphereFriendCity)
                    .foregroundStyle(.secondary)
                    .padding()
                Spacer()
            } else {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        if !hourlyForecast.isEmpty { hourlySection }
                        if !dailyForecast.isEmpty { dailySection }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)
                }

                actionButtons
                    .padding(.horizontal, 16)
                    .padding(.bottom, 20)
            }
        }
        .frame(height: UIScreen.main.bounds.height * 0.50)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
    }

    // MARK: - Hourly Forecast

    private var hourlySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("IDAG")
                .font(.atmosphereSectionHeader)
                .foregroundStyle(.secondary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(hourlyForecast.prefix(12), id: \.date) { hour in
                        VStack(spacing: 6) {
                            Text(Self.hourFormatter.string(from: hour.date))
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                                .foregroundStyle(.secondary)

                            Image(systemName: hour.symbolName)
                                .symbolRenderingMode(.multicolor)
                                .font(.system(size: 18))

                            Text(hour.temperature.converted(to: .celsius)
                                .formatted(.measurement(width: .narrow, usage: .asProvided, numberFormatStyle: .number.precision(.fractionLength(0)))))
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                                .foregroundStyle(.primary)
                        }
                        .frame(minWidth: 48)
                        .padding(.vertical, 10)
                        .padding(.horizontal, 6)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                }
                .padding(.horizontal, 2)
            }
        }
    }

    // MARK: - Daily Forecast

    private var dailySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("5 DAGAR")
                .font(.atmosphereSectionHeader)
                .foregroundStyle(.secondary)

            VStack(spacing: 1) {
                ForEach(Array(dailyForecast.prefix(5).enumerated()), id: \.offset) { idx, day in
                    HStack(spacing: 12) {
                        Text(idx == 0 ? "Idag" : Self.dayFormatter.string(from: day.date).capitalized)
                            .font(.atmosphereFriendCity)
                            .frame(width: 52, alignment: .leading)

                        Image(systemName: day.symbolName)
                            .symbolRenderingMode(.multicolor)
                            .font(.system(size: 16))
                            .frame(width: 22)

                        Spacer()

                        Text(day.lowTemperature.converted(to: .celsius)
                            .formatted(.measurement(width: .narrow, usage: .asProvided, numberFormatStyle: .number.precision(.fractionLength(0)))))
                            .font(.atmosphereFriendCity)
                            .foregroundStyle(.secondary)
                            .frame(width: 36, alignment: .trailing)

                        // Temp range bar
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule()
                                    .fill(Color.white.opacity(0.15))
                                Capsule()
                                    .fill(zone.color.opacity(0.7))
                                    .frame(width: geo.size.width * 0.6)
                            }
                        }
                        .frame(width: 60, height: 4)

                        Text(day.highTemperature.converted(to: .celsius)
                            .formatted(.measurement(width: .narrow, usage: .asProvided, numberFormatStyle: .number.precision(.fractionLength(0)))))
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .frame(width: 36, alignment: .leading)
                    }
                    .padding(.vertical, 10)
                    .padding(.horizontal, 12)
                    .background(idx % 2 == 0 ? Color.white.opacity(0.05) : Color.clear)
                }
            }
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        VStack(spacing: 10) {
            Button {
                shareTarget = friendWeather
            } label: {
                HStack {
                    Image(systemName: "paperplane.fill")
                    Text("Skicka vädervy till \(friendWeather.friend.displayName.components(separatedBy: " ").first ?? "vännen")")
                        .font(.atmosphereFriendName)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(zone.color)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
        }
    }

    // MARK: - Data Loading

    private func loadDetailedWeather() async {
        guard let lat = friendWeather.friend.cityLatitude,
              let lon = friendWeather.friend.cityLongitude else {
            isLoading = false
            errorMessage = "Koordinater saknas."
            return
        }
        do {
            let (_, hourly, daily) = try await weatherService.detailedWeather(latitude: lat, longitude: lon)
            hourlyForecast = Array(hourly)
            dailyForecast = daily.map { Array($0) } ?? []
            isLoading = false
        } catch {
            isLoading = false
            errorMessage = "Kunde inte hämta prognos."
        }
    }
}
