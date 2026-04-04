import SwiftUI
import FirebaseFirestore

struct ConversationListView: View {
    @Environment(ChatService.self) private var chatService
    @Environment(AuthManager.self) private var authManager
    @Environment(AppWeatherService.self) private var weatherService
    @Environment(FriendService.self) private var friendService
    @Environment(UserService.self) private var userService
    @Binding var openConversationId: String?
    @State private var viewModel = ConversationListViewModel()
    @State private var showNewConversation = false
    @State private var navigationPath = NavigationPath()

    private var currentUid: String { authManager.currentUser?.id ?? "" }

    // Sky from current user's location — default sunny
    private var skyMood: SkyMood { .sunny }

    var body: some View {
        NavigationStack(path: $navigationPath) {
            ZStack(alignment: .bottom) {
                // Sky background
                AtmosphereSkyBackground(mood: skyMood)
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Floating header
                    HStack {
                        Text("Chattar")
                            .font(.bubbleH1)
                            .foregroundStyle(Color.atmosphereTextOnSky)
                            .shadow(radius: 4)

                        Spacer()

                        Button {
                            showNewConversation = true
                        } label: {
                            Image(systemName: "square.and.pencil")
                                .font(.system(size: 17, weight: .medium))
                                .foregroundStyle(Color.atmosphereTextOnSky)
                                .frame(width: 36, height: 36)
                                .background(.ultraThinMaterial)
                                .clipShape(Circle())
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 60)
                    .padding(.bottom, 16)

                    // Glass sheet with conversation list
                    conversationListContent
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                        .ignoresSafeArea(edges: .bottom)
                }
            }
            .ignoresSafeArea()
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: String.self) { conversationId in
                ChatView(conversationId: conversationId)
            }
            .sheet(isPresented: $showNewConversation) {
                NewConversationSheet { conversationId in
                    showNewConversation = false
                    navigationPath.append(conversationId)
                }
            }
            .task {
                guard !currentUid.isEmpty else { return }
                await viewModel.load(uid: currentUid, chatService: chatService, friendService: friendService, userService: userService)
            }
            .onChange(of: chatService.conversations) { _, newConversations in
                Task {
                    await viewModel.refreshUsersMapIfNeeded(
                        conversations: newConversations,
                        currentUid: currentUid,
                        userService: userService
                    )
                }
            }
            .onChange(of: openConversationId) { _, newId in
                if let id = newId {
                    navigationPath.append(id)
                    openConversationId = nil
                }
            }
        }
    }

    @ViewBuilder
    private var conversationListContent: some View {
        let filtered = viewModel.filteredConversations(
            from: chatService.conversations,
            currentUid: currentUid
        )

        if filtered.isEmpty && !viewModel.isLoading {
            VStack(spacing: 16) {
                Spacer()
                Image(systemName: "bubble.left.and.bubble.right")
                    .font(.system(size: 48))
                    .foregroundStyle(.secondary)

                Text("Inga chattar ännu")
                    .font(.atmosphereFriendName)
                    .foregroundStyle(.primary)

                Text("Starta en konversation med en vän om vädret")
                    .font(.atmosphereFriendCity)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                Spacer()
            }
            .padding(32)
        } else {
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(filtered) { conversation in
                        Button {
                            if let id = conversation.id {
                                navigationPath.append(id)
                            }
                        } label: {
                            AtmosphereConversationRow(
                                conversation: conversation,
                                displayName: viewModel.displayName(for: conversation, currentUid: currentUid),
                                otherUser: viewModel.otherUser(for: conversation, currentUid: currentUid),
                                timeString: viewModel.formattedTime(conversation.lastMessageAt),
                                weatherService: weatherService
                            )
                        }
                        .buttonStyle(.plain)

                        Divider()
                            .opacity(0.12)
                            .padding(.leading, 72)
                    }
                }
                .padding(.top, 4)
                .padding(.bottom, 32)
            }
        }
    }
}

// MARK: - AtmosphereConversationRow

private struct AtmosphereConversationRow: View {
    let conversation: Conversation
    let displayName: String
    let otherUser: AppUser?
    let timeString: String
    let weatherService: AppWeatherService

    @State private var weatherSymbol: String?
    @State private var weatherCelsius: Double?

    var body: some View {
        HStack(spacing: 12) {
            profileAvatar

            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    Text(displayName)
                        .font(.atmosphereFriendName)
                        .lineLimit(1)
                    Spacer()
                    Text(timeString)
                        .font(.atmosphereFriendCity)
                        .foregroundStyle(.secondary)
                }
                HStack {
                    Text(conversation.lastMessage ?? "Starta en konversation")
                        .font(.atmosphereFriendCity)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                    Spacer()
                    if let symbol = weatherSymbol {
                        Image(systemName: symbol)
                            .font(.system(size: 13))
                            .foregroundStyle(
                                weatherCelsius.map { TemperatureZone(celsius: $0).color } ?? Color.secondary
                            )
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .task {
            await loadWeather()
        }
    }

    @ViewBuilder
    private var profileAvatar: some View {
        if conversation.isGroup {
            ZStack {
                Circle().fill(Color(.systemGray5))
                Image(systemName: "person.3.fill")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(width: 44, height: 44)
        } else {
            TemperatureRingAvatar(
                photoURL: otherUser?.photoURL,
                displayName: displayName,
                temperatureCelsius: weatherCelsius,
                size: 44
            )
        }
    }

    private func loadWeather() async {
        guard let lat = otherUser?.cityLatitude, let lon = otherUser?.cityLongitude else { return }
        if let weather = try? await weatherService.currentWeather(latitude: lat, longitude: lon) {
            weatherSymbol = weather.symbolName
            weatherCelsius = weather.temperature.converted(to: .celsius).value
        }
    }
}
