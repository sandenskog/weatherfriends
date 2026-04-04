import SwiftUI
import WeatherKit

// MARK: - FriendsTab Enum

enum FriendsTab: String, CaseIterable {
    case list    = "Lista"
    case map     = "Karta"
    case zones   = "Zoner"
}

// MARK: - FriendsTabView

struct FriendsTabView: View {
    @Binding var openWeatherAlertFriendId: String?

    @Environment(AuthManager.self)        private var authManager
    @Environment(AppWeatherService.self)  private var weatherService
    @Environment(FriendService.self)      private var friendService
    @Environment(WeatherAlertService.self) private var weatherAlertService
    @Environment(InviteService.self)      private var inviteService
    @Environment(UserService.self)        private var userService
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var selectedTab: FriendsTab = .list
    @State private var viewModel = FriendListViewModel()
    @State private var selectedFriendWeather: FriendWeather?
    @State private var attribution: WeatherAttribution?
    @State private var inviteURL: URL?
    @State private var showProfile = false
    @State private var showManualAdd = false
    @State private var showAddFriend = false
    @State private var showContactImport = false
    @State private var showDigestPreview = false
    @State private var shareTarget: FriendWeather?
    @State private var dailyNotificationService = DailyWeatherNotificationService()

    private var skyMood: SkyMood {
        guard let weather = viewModel.myWeather else { return .partlyCloudy }
        let isDaytime = weather.weather.map { $0.isDaylight } ?? true
        return SkyMood.from(symbolName: weather.symbolName, isDaytime: isDaytime)
    }

    private var tabOptions: [(label: String, value: FriendsTab)] {
        FriendsTab.allCases.map { (label: $0.rawValue, value: $0) }
    }

    // MARK: - Body

    var body: some View {
        mainContent
        // All sheets attached to outer container, NOT inside GeometryReader
        .sheet(item: $selectedFriendWeather) { fw in
            WeatherDetailSheet(friendWeather: fw)
                .environment(weatherService)
        }
        .sheet(item: $shareTarget) { fw in
            WeatherCardPreviewSheet(friendWeather: fw, myWeather: viewModel.myWeather)
        }
        .sheet(isPresented: $showManualAdd) {
            ManualAddFriendSheet(uid: "", friendService: friendService) {
                Task { await reloadFriends() }
            }
        }
        .sheet(isPresented: $showAddFriend) {
            if let uid = authManager.currentUser?.id {
                AddFriendSheet(uid: uid, friendService: friendService) {
                    Task { await reloadFriends() }
                }
            } else {
                Text("Logga in för att lägga till vänner")
                    .font(.bubbleBody)
                    .foregroundStyle(.secondary)
                    .padding()
            }
        }
        .sheet(isPresented: $showContactImport) {
            if let uid = authManager.currentUser?.id {
                ContactImportView(uid: uid, friendService: friendService) {
                    Task { await reloadFriends() }
                }
            } else {
                Text("Logga in för att importera kontakter")
                    .font(.bubbleBody)
                    .foregroundStyle(.secondary)
                    .padding()
            }
        }
        .sheet(isPresented: $showProfile) {
            if let uid = authManager.currentUser?.id {
                ProfileView(uid: uid)
            } else {
                // No user — show placeholder
                Text("Inte inloggad")
                    .padding()
            }
        }
        .sheet(isPresented: $showDigestPreview) {
            DigestPreviewSheet(friends: viewModel.favorites + viewModel.others)
        }
        .alert("Fel", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("OK") { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .task {
            guard let uid = authManager.currentUser?.id else {
                // No auth — load demo data anyway so UI isn't empty
                await viewModel.loadDemo()
                return
            }
            await viewModel.load(
                uid: uid,
                friendService: friendService,
                weatherService: weatherService,
                currentUser: authManager.currentUser
            )
            await dailyNotificationService.schedule(favorites: viewModel.favorites)
        }
        .task {
            attribution = try? await weatherService.attribution
        }
        .task {
            guard let uid = authManager.currentUser?.id else { return }
            if let token = try? await inviteService.getOrCreateInviteToken(for: uid, userService: userService) {
                inviteURL = inviteService.inviteURL(token: token)
            }
        }
        .onChange(of: openWeatherAlertFriendId) { _, friendId in
            guard let friendId, !viewModel.isLoading else { return }
            let all = viewModel.favorites + viewModel.others
            selectedFriendWeather = all.first(where: { $0.friend.id == friendId })
            openWeatherAlertFriendId = nil
        }
        .onChange(of: viewModel.isLoading) { _, isLoading in
            guard !isLoading, let friendId = openWeatherAlertFriendId else { return }
            let all = viewModel.favorites + viewModel.others
            selectedFriendWeather = all.first(where: { $0.friend.id == friendId })
            openWeatherAlertFriendId = nil
        }
    }

    // MARK: - Main Content (extracted from body to avoid GeometryReader sheet issues)

    private var mainContent: some View {
        GeometryReader { geo in
            ZStack(alignment: .bottom) {
                // Sky — full bleed, never intercepts taps
                AtmosphereSkyBackground(mood: skyMood)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)

                // Hero weather on sky (top area)
                VStack(spacing: 0) {
                    myWeatherHero
                        .padding(.top, geo.safeAreaInsets.top + 12)
                        .padding(.horizontal, 20)
                    Spacer()
                }

                // Glass sheet pinned to bottom
                glassSheet(geo: geo)
                    .ignoresSafeArea(edges: .bottom)
            }
            .ignoresSafeArea()
        }
    }

    // MARK: - My Weather Hero

    private var myWeatherHero: some View {
        HStack(alignment: .top, spacing: 12) {
            // Left: weather data
            VStack(alignment: .leading, spacing: 4) {
                if let my = viewModel.myWeather {
                    Text(my.friend.city)
                        .font(.atmosphereCity)
                        .foregroundStyle(Color.atmosphereTextOnSky)
                        .shadow(color: .black.opacity(0.3), radius: 4)

                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text(my.temperatureFormatted)
                            .font(.atmosphereDisplayTemp)
                            .foregroundStyle(Color.atmosphereTextOnSky)
                            .shadow(color: .black.opacity(0.3), radius: 8)

                        Image(systemName: my.symbolName)
                            .symbolRenderingMode(.multicolor)
                            .font(.system(size: 28))
                            .shadow(color: .black.opacity(0.25), radius: 4)
                    }

                    Text(my.conditionDescription)
                        .font(.atmosphereCondition)
                        .foregroundStyle(Color.atmosphereTextOnSkySecondary)
                        .shadow(color: .black.opacity(0.2), radius: 3)
                } else {
                    // No user / loading state — minimal placeholder
                    Text("FriendsCast")
                        .font(.atmosphereCity)
                        .foregroundStyle(Color.atmosphereTextOnSkySecondary)
                        .shadow(color: .black.opacity(0.2), radius: 3)
                }
            }

            Spacer()

            // Right: action buttons
            VStack(spacing: 8) {
                // Add friend
                Menu {
                    Button { showManualAdd = true } label: {
                        Label("Lägg till manuellt", systemImage: "pencil")
                    }
                    Button { showContactImport = true } label: {
                        Label("Importera kontakter", systemImage: "person.crop.circle.badge.plus")
                    }
                    Button { showAddFriend = true } label: {
                        Label("Lös in inbjudningslänk", systemImage: "link.badge.plus")
                    }
                    if !viewModel.favorites.isEmpty || !viewModel.others.isEmpty {
                        Divider()
                        Button { showDigestPreview = true } label: {
                            Label("Daily Digest", systemImage: "newspaper")
                        }
                    }
                    if let inviteURL {
                        Divider()
                        ShareLink(
                            item: inviteURL,
                            subject: Text("FriendsCast"),
                            message: Text("Kom och se vädret hos dina vänner i FriendsCast!")
                        ) {
                            Label("Bjud in vänner", systemImage: "square.and.arrow.up")
                        }
                    }
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 36, height: 36)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                        .shadow(color: .black.opacity(0.2), radius: 4)
                }
            }
        }
    }

    @ViewBuilder
    private var profileButtonContent: some View {
        if let urlString = authManager.currentUser?.photoURL,
           let url = URL(string: urlString) {
            AsyncImage(url: url) { phase in
                if let image = phase.image {
                    image.resizable().scaledToFill()
                        .frame(width: 36, height: 36)
                        .clipShape(Circle())
                        .shadow(color: .black.opacity(0.3), radius: 4)
                } else {
                    initialsCircle
                }
            }
        } else {
            initialsCircle
        }
    }

    private var initialsCircle: some View {
        ZStack {
            Circle().fill(.ultraThinMaterial)
            if let name = authManager.currentUser?.displayName, !name.isEmpty {
                Text(String(name.prefix(1)).uppercased())
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
            } else {
                Image(systemName: "person.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(.white.opacity(0.8))
            }
        }
        .frame(width: 36, height: 36)
        .shadow(color: .black.opacity(0.2), radius: 4)
    }

    // MARK: - Glass Sheet

    private func glassSheet(geo: GeometryProxy) -> some View {
        let sheetHeight = geo.size.height * 0.57 + geo.safeAreaInsets.bottom

        return VStack(spacing: 0) {
            // Drag pill
            Capsule()
                .fill(Color.white.opacity(0.4))
                .frame(width: 36, height: 4)
                .padding(.top, 10)
                .padding(.bottom, 10)

            // Segment picker
            AtmosphereSegmentedPicker(options: tabOptions, selection: $selectedTab)
                .padding(.horizontal, 16)
                .padding(.bottom, 10)

            // Content
            Group {
                switch selectedTab {
                case .list:
                    if viewModel.isLoading && viewModel.favorites.isEmpty && viewModel.others.isEmpty {
                        loadingView
                    } else {
                        FriendListView(
                            viewModel: viewModel,
                            selectedFriendWeather: $selectedFriendWeather,
                            shareTarget: $shareTarget,
                            attribution: attribution,
                            uid: authManager.currentUser?.id,
                            friendService: friendService,
                            weatherService: weatherService,
                            authManager: authManager
                        )
                    }
                case .map:
                    FriendMapView(friendWeathers: viewModel.favorites + viewModel.others)
                case .zones:
                    FriendCategoryView(
                        friendWeathers: viewModel.favorites + viewModel.others,
                        selectedFriendWeather: $selectedFriendWeather
                    )
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(height: sheetHeight)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .shadow(color: .black.opacity(0.12), radius: 20, y: -4)
    }

    private var loadingView: some View {
        VStack(spacing: 12) {
            Spacer()
            ProgressView()
            Text("Hämtar väder...")
                .font(.atmosphereFriendCity)
                .foregroundStyle(.secondary)
            Spacer()
        }
    }

    // MARK: - Helpers

    private func reloadFriends() async {
        guard let uid = authManager.currentUser?.id else { return }
        await viewModel.load(
            uid: uid,
            friendService: friendService,
            weatherService: weatherService,
            currentUser: authManager.currentUser
        )
    }
}
