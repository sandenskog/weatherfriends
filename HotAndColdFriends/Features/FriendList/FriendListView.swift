import SwiftUI
import WeatherKit

struct FriendListView: View {
    @Environment(AuthManager.self) private var authManager
    @Environment(AppWeatherService.self) private var weatherService
    @Environment(FriendService.self) private var friendService
    @State private var viewModel = FriendListViewModel()
    @State private var selectedFriendWeather: FriendWeather?
    @State private var showProfile = false
    @State private var attribution: WeatherAttribution?

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.favorites.isEmpty && viewModel.others.isEmpty {
                    ProgressView("Hämtar väderdata...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    mainList
                }
            }
            .navigationTitle("Hot & Cold Friends")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showProfile = true
                    } label: {
                        Image(systemName: "person.circle")
                            .font(.title3)
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
        }
        .task {
            attribution = try? await weatherService.attribution
        }
    }

    // MARK: - Main List

    private var mainList: some View {
        List {
            if viewModel.showDemoBanner {
                demoBanner
            }

            if !viewModel.favorites.isEmpty {
                favoritesSection
            }

            othersSection

            if let attribution {
                attributionFooter(attribution)
            }
        }
        .listStyle(.insetGrouped)
        .refreshable {
            guard let uid = authManager.currentUser?.id else { return }
            await viewModel.refresh(uid: uid, friendService: friendService, weatherService: weatherService)
        }
    }

    // MARK: - Demo Banner

    private var demoBanner: some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "info.circle.fill")
                        .foregroundStyle(.orange)
                    Text("Exempeldata")
                        .font(.subheadline.weight(.semibold))
                }
                Text("Lagg till dina egna vanner for att se deras vader")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Button {
                    Task {
                        guard let uid = authManager.currentUser?.id else { return }
                        await viewModel.removeDemoData(uid: uid, friendService: friendService)
                    }
                } label: {
                    Text("Ta bort exempeldata")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.orange)
                }
            }
            .padding(.vertical, 4)
            .listRowBackground(Color.orange.opacity(0.08))
        }
    }

    // MARK: - Favorites Section

    private var favoritesSection: some View {
        Section("Favoriter") {
            ForEach(viewModel.favorites) { fw in
                FriendRowView(friendWeather: fw)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedFriendWeather = fw
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button {
                            Task {
                                guard let uid = authManager.currentUser?.id else { return }
                                await viewModel.toggleFavorite(uid: uid, friend: fw.friend, friendService: friendService)
                            }
                        } label: {
                            Label("Ta bort favorit", systemImage: "star.slash")
                        }
                        .tint(.orange)
                    }
            }
        }
    }

    // MARK: - Others Section

    private var othersSection: some View {
        Section(viewModel.favorites.isEmpty ? "Vanner" : "Ovriga") {
            ForEach(viewModel.others) { fw in
                FriendRowView(friendWeather: fw)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedFriendWeather = fw
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button {
                            Task {
                                guard let uid = authManager.currentUser?.id else { return }
                                await viewModel.toggleFavorite(uid: uid, friend: fw.friend, friendService: friendService)
                            }
                        } label: {
                            Label("Favorit", systemImage: "star")
                        }
                        .tint(.yellow)
                    }
            }
        }
    }

    // MARK: - Attribution Footer

    private func attributionFooter(_ attribution: WeatherAttribution) -> some View {
        Section {
            HStack(spacing: 8) {
                AsyncImage(url: attribution.combinedMarkLightURL) { phase in
                    if let image = phase.image {
                        image
                            .resizable()
                            .scaledToFit()
                            .frame(height: 20)
                    }
                }
                Link("Vaderdata fran Apple", destination: attribution.legalPageURL)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .listRowBackground(Color.clear)
        }
    }
}
