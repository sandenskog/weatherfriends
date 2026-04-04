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
    @State private var showAddFriend = false
    @State private var showContactImport = false
    @State private var showDigestPreview = false
    @State private var dailyNotificationService = DailyWeatherNotificationService()

    // Sky mood derived from user's own weather
    private var skyMood: SkyMood {
        guard let weather = viewModel.myWeather else { return .sunny }
        let isDaytime = weather.weather.map { $0.isDaylight } ?? true
        return SkyMood.from(symbolName: weather.symbolName, isDaytime: isDaytime)
    }

    private var tabOptions: [(label: String, value: FriendsTab)] {
        FriendsTab.allCases.map { (label: $0.rawValue, value: $0) }
    }

    // MARK: - Body

    var body: some View {
        ZStack(alignment: .top) {
            // 1. Living sky background
            AtmosphereSkyBackground(mood: skyMood)
                .ignoresSafeArea()

            // 2. My weather hero — floating on sky
            VStack(spacing: 0) {
                myWeatherHero
                    .padding(.top, 60)
                    .padding(.horizontal, 20)

                Spacer()
            }

            // 3. Glass sheet rising from bottom
            VStack(spacing: 0) {
                Spacer()
                glassSheet
            }
            .ignoresSafeArea(edges: .bottom)
        }
        .ignoresSafeArea()
        // Sheets
        .sheet(item: $selectedFriendWeather) { fw in
            WeatherDetailSheet(friendWeather: fw)
                .environment(weatherService)
        }
        .sheet(isPresented: $showAddFriend) {
            if let uid = authManager.currentUser?.id {
                AddFriendSheet(uid: uid, friendService: friendService) {
                    Task { await reloadFriends() }
                }
            }
        }
        .sheet(isPresented: $showContactImport) {
            if let uid = authManager.currentUser?.id {
                ContactImportView(uid: uid, friendService: friendService) {
                    Task { await reloadFriends() }
                }
            }
        }
        .sheet(isPresented: $showProfile) {
            if let uid = authManager.currentUser?.id {
                ProfileView(uid: uid)
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
        // Data tasks
        .task {
            guard let uid = authManager.currentUser?.id else { return }
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

    // MARK: - My Weather Hero (on sky)

    private var myWeatherHero: some View {
        HStack(alignment: .top) {
            // Weather info
            VStack(alignment: .leading, spacing: 4) {
                if let my = viewModel.myWeather {
                    Text(my.friend.city)
                        .font(.atmosphereCity)
                        .foregroundStyle(Color.atmosphereTextOnSky)
                        .shadow(radius: 4)

                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text(my.temperatureFormatted)
                            .font(.atmosphereDisplayTemp)
                            .foregroundStyle(Color.atmosphereTextOnSky)
                            .shadow(radius: 6)

                        Image(systemName: my.symbolName)
                            .symbolRenderingMode(.multicolor)
                            .font(.system(size: 32))
                            .shadow(radius: 4)
                    }

                    Text(my.conditionDescription)
                        .font(.atmosphereCondition)
                        .foregroundStyle(Color.atmosphereTextOnSkySecondary)
                        .shadow(radius: 3)
                } else {
                    Text("Ditt väder")
                        .font(.atmosphereCity)
                        .foregroundStyle(Color.atmosphereTextOnSkyMuted)
                }
            }

            Spacer()

            // Top-right actions
            VStack(spacing: 10) {
                // Profile button
                Button { showProfile = true } label: {
                    if let urlString = authManager.currentUser?.photoURL,
                       let url = URL(string: urlString) {
                        AsyncImage(url: url) { phase in
                            if let image = phase.image {
                                image.resizable().scaledToFill()
                                    .frame(width: 36, height: 36)
                                    .clipShape(Circle())
                            } else {
                                profilePlaceholder
                            }
                        }
                    } else {
                        profilePlaceholder
                    }
                }

                // Add friend menu
                Menu {
                    Button {
                        showAddFriend = true
                    } label: {
                        Label("Lägg till manuellt", systemImage: "pencil")
                    }
                    Button {
                        showContactImport = true
                    } label: {
                        Label("Importera kontakter", systemImage: "person.crop.circle.badge.plus")
                    }
                    if !viewModel.favorites.isEmpty || !viewModel.others.isEmpty {
                        Divider()
                        Button {
                            showDigestPreview = true
                        } label: {
                            Label("Daily Digest", systemImage: "newspaper")
                        }
                    }
                    if let inviteURL {
                        Divider()
                        ShareLink(
                            item: inviteURL,
                            subject: Text("FriendsCast"),
                            message: Text("\(authManager.currentUser?.displayName ?? "Jag") bjuder in dig till FriendsCast!")
                        ) {
                            Label("Bjud in vänner", systemImage: "square.and.arrow.up")
                        }
                    }
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 32, height: 32)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                }
            }
        }
    }

    private var profilePlaceholder: some View {
        ZStack {
            Circle().fill(.ultraThinMaterial)
            Text(authManager.currentUser?.displayName.prefix(1).uppercased() ?? "?")
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
        }
        .frame(width: 36, height: 36)
    }

    // MARK: - Glass Sheet

    private var glassSheet: some View {
        VStack(spacing: 0) {
            // Drag indicator
            Capsule()
                .fill(Color.white.opacity(0.35))
                .frame(width: 36, height: 4)
                .padding(.top, 12)
                .padding(.bottom, 8)

            // Segment picker
            AtmosphereSegmentedPicker(options: tabOptions, selection: $selectedTab)
                .padding(.horizontal, 16)
                .padding(.bottom, 12)

            // Content
            Group {
                switch selectedTab {
                case .list:
                    if viewModel.isLoading && viewModel.favorites.isEmpty && viewModel.others.isEmpty {
                        loadingState
                    } else {
                        FriendListView(
                            viewModel: viewModel,
                            selectedFriendWeather: $selectedFriendWeather,
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
        .frame(height: UIScreen.main.bounds.height * 0.62)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
    }

    private var loadingState: some View {
        VStack(spacing: 12) {
            Spacer()
            ProgressView()
                .scaleEffect(1.2)
            Text("Hämtar väderdata...")
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
