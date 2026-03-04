import SwiftUI
import WeatherKit

// MARK: - FriendsTab Enum

enum FriendsTab: String, CaseIterable {
    case list = "Lista"
    case map = "Karta"
    case categories = "Kategorier"
}

// MARK: - FriendsTabView

struct FriendsTabView: View {
    @Binding var openWeatherAlertFriendId: String?
    @Environment(AuthManager.self) private var authManager
    @Environment(AppWeatherService.self) private var weatherService
    @Environment(FriendService.self) private var friendService

    @State private var selectedTab: FriendsTab = .list
    @State private var viewModel = FriendListViewModel()
    @State private var selectedFriendWeather: FriendWeather?
    @State private var dailyNotificationService = DailyWeatherNotificationService()
    @State private var showProfile = false
    @State private var showAddFriend = false
    @State private var showContactImport = false
    @State private var attribution: WeatherAttribution?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("Vy", selection: $selectedTab) {
                    ForEach(FriendsTab.allCases, id: \.self) {
                        Text($0.rawValue).tag($0)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.top, 8)
                .padding(.bottom, 4)

                Group {
                    switch selectedTab {
                    case .list:
                        if viewModel.isLoading && viewModel.favorites.isEmpty && viewModel.others.isEmpty {
                            ProgressView("Hämtar väderdata...")
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
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
                    case .categories:
                        FriendCategoryView(
                            friendWeathers: viewModel.favorites + viewModel.others,
                            selectedFriendWeather: $selectedFriendWeather
                        )
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .navigationTitle("Hot & Cold Friends")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 12) {
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
                        } label: {
                            Image(systemName: "plus")
                                .font(.body.weight(.medium))
                        }
                        Button {
                            showProfile = true
                        } label: {
                            Image(systemName: "person.circle")
                                .font(.title3)
                        }
                    }
                }
                ToolbarItem(placement: .topBarLeading) {
                    Button(role: .destructive) {
                        authManager.signOut()
                    } label: {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                            .font(.body)
                    }
                    .tint(.secondary)
                }
            }
        }
        .sheet(item: $selectedFriendWeather) { fw in
            WeatherDetailSheet(friendWeather: fw)
                .environment(weatherService)
        }
        .sheet(isPresented: $showAddFriend) {
            if let uid = authManager.currentUser?.id {
                AddFriendSheet(uid: uid, friendService: friendService) {
                    Task {
                        await viewModel.load(uid: uid, friendService: friendService, weatherService: weatherService)
                    }
                }
            }
        }
        .sheet(isPresented: $showContactImport) {
            if let uid = authManager.currentUser?.id {
                ContactImportView(uid: uid, friendService: friendService) {
                    Task {
                        await viewModel.load(uid: uid, friendService: friendService, weatherService: weatherService)
                    }
                }
            }
        }
        .sheet(isPresented: $showProfile) {
            if let uid = authManager.currentUser?.id {
                ProfileView(uid: uid)
            }
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
            guard let uid = authManager.currentUser?.id else { return }
            await viewModel.load(uid: uid, friendService: friendService, weatherService: weatherService)
            // Schemalägg daglig notis med aktuell favoritdata
            await dailyNotificationService.schedule(favorites: viewModel.favorites)
        }
        .task {
            attribution = try? await weatherService.attribution
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
}
