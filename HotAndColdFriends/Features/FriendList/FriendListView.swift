import SwiftUI
import WeatherKit

struct FriendListView: View {
    let viewModel: FriendListViewModel
    @Binding var selectedFriendWeather: FriendWeather?
    let attribution: WeatherAttribution?
    let uid: String?
    let friendService: FriendService
    let weatherService: AppWeatherService
    let authManager: AuthManager

    var body: some View {
        mainList
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
            guard let uid else { return }
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
                Text("Lägg till dina egna vänner för att se deras väder")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Button {
                    Task {
                        guard let uid else { return }
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
                                guard let uid else { return }
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
        Section(viewModel.favorites.isEmpty ? "Vänner" : "Övriga") {
            ForEach(viewModel.others) { fw in
                FriendRowView(friendWeather: fw)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedFriendWeather = fw
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button {
                            Task {
                                guard let uid else { return }
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
                Link("Väderdata från Apple", destination: attribution.legalPageURL)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .listRowBackground(Color.clear)
        }
    }
}
