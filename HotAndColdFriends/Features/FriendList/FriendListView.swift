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

    @State private var heartPopFriendId: String?
    @State private var shareTarget: FriendWeather?
    @State private var favoriteTrigger = false
    @Environment(WeatherAlertService.self) private var weatherAlertService
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        mainList
    }

    // MARK: - Main List

    private var mainList: some View {
        Group {
            if viewModel.others.isEmpty && viewModel.favorites.isEmpty && !viewModel.showDemoBanner {
                emptyStateFriends
            } else {
                ScrollView {
                    LazyVStack(spacing: 0, pinnedViews: []) {
                        if viewModel.showDemoBanner {
                            demoBanner
                                .padding(.horizontal, 16)
                                .padding(.top, 8)
                        }

                        if !viewModel.favorites.isEmpty {
                            favoritesSection
                        }

                        othersSection

                        if let attribution {
                            attributionFooter(attribution)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                        }
                    }
                }
                .sensoryFeedback(.impact(weight: .medium), trigger: favoriteTrigger)
                .sheet(item: $shareTarget) { fw in
                    WeatherCardPreviewSheet(friendWeather: fw, myWeather: viewModel.myWeather)
                }
                .cloudRefreshable {
                    guard let uid else { return }
                    await viewModel.refresh(uid: uid, friendService: friendService, weatherService: weatherService, currentUser: authManager.currentUser)
                    let allFriends = viewModel.favorites.map(\.friend) + viewModel.others.map(\.friend)
                    await weatherAlertService.checkAlertsForFriends(uid: uid, friends: allFriends)
                }
            }
        }
    }

    // MARK: - Empty State

    private var emptyStateFriends: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "person.2")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            Text("No friends yet")
                .font(.atmosphereFriendName)
                .foregroundStyle(.primary)

            Text("Add friends to see their weather")
                .font(.atmosphereFriendCity)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Spacer()
        }
        .padding(32)
    }

    // MARK: - Demo Banner

    private var demoBanner: some View {
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
        .padding(12)
        .background(Color.orange.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Favorites Section

    private var favoritesSection: some View {
        VStack(spacing: 0) {
            ZoneDivider(zone: .tropical, friendCount: viewModel.favorites.count)

            ForEach(Array(viewModel.favorites.enumerated()), id: \.element.id) { index, fw in
                FriendRowView(friendWeather: fw)
                    .heartPop(isActive: heartPopFriendId != nil && heartPopFriendId == fw.friend.id)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .animation(
                        reduceMotion
                            ? .easeInOut(duration: 0.25)
                            : .spring(response: 0.35, dampingFraction: 0.7)
                                .delay(Double(index) * 0.05),
                        value: viewModel.refreshToken
                    )
                    .contentShape(Rectangle())
                    .onTapGesture { selectedFriendWeather = fw }
                    .swipeActions(edge: .leading, allowsFullSwipe: false) {
                        Button { shareTarget = fw } label: {
                            Label("Share", systemImage: "square.and.arrow.up")
                        }
                        .tint(.blue)
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button {
                            if let fid = fw.friend.id { triggerHeartPop(friendId: fid) }
                            Task {
                                guard let uid else { return }
                                await viewModel.toggleFavorite(uid: uid, friend: fw.friend, friendService: friendService)
                            }
                        } label: {
                            Label("Ta bort favorit", systemImage: "star.slash")
                        }
                        .tint(.orange)
                    }

                if index < viewModel.favorites.count - 1 {
                    Divider()
                        .opacity(0.12)
                        .padding(.leading, 72)
                }
            }
        }
    }

    // MARK: - Others Section

    private var othersSection: some View {
        let zone: TemperatureZone = viewModel.others.first.flatMap {
            $0.temperatureCelsius.map { TemperatureZone(celsius: $0) }
        } ?? .cool

        return VStack(spacing: 0) {
            ZoneDivider(zone: zone, friendCount: viewModel.others.count)

            ForEach(Array(viewModel.others.enumerated()), id: \.element.id) { index, fw in
                FriendRowView(friendWeather: fw)
                    .heartPop(isActive: heartPopFriendId != nil && heartPopFriendId == fw.friend.id)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .animation(
                        reduceMotion
                            ? .easeInOut(duration: 0.25)
                            : .spring(response: 0.35, dampingFraction: 0.7)
                                .delay(Double(index) * 0.05),
                        value: viewModel.refreshToken
                    )
                    .contentShape(Rectangle())
                    .onTapGesture { selectedFriendWeather = fw }
                    .swipeActions(edge: .leading, allowsFullSwipe: false) {
                        Button { shareTarget = fw } label: {
                            Label("Share", systemImage: "square.and.arrow.up")
                        }
                        .tint(.blue)
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button {
                            if let fid = fw.friend.id { triggerHeartPop(friendId: fid) }
                            Task {
                                guard let uid else { return }
                                await viewModel.toggleFavorite(uid: uid, friend: fw.friend, friendService: friendService)
                            }
                        } label: {
                            Label("Favorit", systemImage: "star")
                        }
                        .tint(.yellow)
                    }

                if index < viewModel.others.count - 1 {
                    Divider()
                        .opacity(0.12)
                        .padding(.leading, 72)
                }
            }
        }
    }

    // MARK: - Heart Pop Helper

    private func triggerHeartPop(friendId: String) {
        heartPopFriendId = friendId
        favoriteTrigger.toggle()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            heartPopFriendId = nil
        }
    }

    // MARK: - Attribution Footer

    private func attributionFooter(_ attribution: WeatherAttribution) -> some View {
        HStack(spacing: 8) {
            AsyncImage(url: attribution.combinedMarkLightURL) { phase in
                if let image = phase.image {
                    image.resizable().scaledToFit().frame(height: 20)
                }
            }
            Link("Väderdata från Apple", destination: attribution.legalPageURL)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
