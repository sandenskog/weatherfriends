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
                .cloudRefreshable {
                    guard let uid else { return }
                    await viewModel.refresh(uid: uid, friendService: friendService, weatherService: weatherService)
                }
            }
        }
    }

    // MARK: - Empty State

    private var emptyStateFriends: some View {
        VStack(spacing: 16) {
            Spacer()
            Image("EmptyStateFriends")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxWidth: 200)

            Text("No friends yet")
                .font(.title3.weight(.semibold))
                .foregroundStyle(.primary)

            Text("Add friends to see their weather")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Spacer()
        }
        .padding(32)
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
            ForEach(Array(viewModel.favorites.enumerated()), id: \.element.id) { index, fw in
                FriendRowView(friendWeather: fw)
                    .heartPop(isActive: heartPopFriendId != nil && heartPopFriendId == fw.friend.id)
                    .transition(.asymmetric(
                        insertion: reduceMotion
                            ? .opacity
                            : .move(edge: .trailing).combined(with: .opacity),
                        removal: .opacity
                    ))
                    .animation(
                        reduceMotion
                            ? .easeInOut(duration: 0.25)
                            : .spring(response: 0.35, dampingFraction: 0.7)
                                .delay(Double(index) * 0.05),
                        value: viewModel.refreshToken
                    )
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedFriendWeather = fw
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
            }
        }
    }

    // MARK: - Others Section

    private var othersSection: some View {
        Section(viewModel.favorites.isEmpty ? "Vänner" : "Övriga") {
            ForEach(Array(viewModel.others.enumerated()), id: \.element.id) { index, fw in
                FriendRowView(friendWeather: fw)
                    .heartPop(isActive: heartPopFriendId != nil && heartPopFriendId == fw.friend.id)
                    .transition(.asymmetric(
                        insertion: reduceMotion
                            ? .opacity
                            : .move(edge: .trailing).combined(with: .opacity),
                        removal: .opacity
                    ))
                    .animation(
                        reduceMotion
                            ? .easeInOut(duration: 0.25)
                            : .spring(response: 0.35, dampingFraction: 0.7)
                                .delay(Double(index) * 0.05),
                        value: viewModel.refreshToken
                    )
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedFriendWeather = fw
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
            }
        }
    }

    // MARK: - Heart Pop Helper

    private func triggerHeartPop(friendId: String) {
        heartPopFriendId = friendId
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            heartPopFriendId = nil
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
