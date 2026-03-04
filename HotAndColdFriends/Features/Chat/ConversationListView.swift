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

    private var currentUid: String {
        authManager.currentUser?.id ?? ""
    }

    var body: some View {
        NavigationStack(path: $navigationPath) {
            conversationList
                .navigationTitle("Chattar")
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            showNewConversation = true
                        } label: {
                            Image(systemName: "square.and.pencil")
                        }
                    }
                }
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
    private var conversationList: some View {
        let filtered = viewModel.filteredConversations(
            from: chatService.conversations,
            currentUid: currentUid
        )

        if filtered.isEmpty && !viewModel.isLoading {
            ContentUnavailableView(
                "Inga chattar än",
                systemImage: "bubble.left.and.bubble.right",
                description: Text("Tryck på pennan uppe till höger för att starta en konversation")
            )
        } else {
            List(filtered) { conversation in
                Button {
                    if let id = conversation.id {
                        navigationPath.append(id)
                    }
                } label: {
                    ConversationRowView(
                        conversation: conversation,
                        displayName: viewModel.displayName(for: conversation, currentUid: currentUid),
                        otherUser: viewModel.otherUser(for: conversation, currentUid: currentUid),
                        timeString: viewModel.formattedTime(conversation.lastMessageAt),
                        weatherService: weatherService
                    )
                }
                .buttonStyle(.plain)
            }
            .listStyle(.plain)
        }
    }
}

// MARK: - ConversationRowView

private struct ConversationRowView: View {
    let conversation: Conversation
    let displayName: String
    let otherUser: AppUser?
    let timeString: String
    let weatherService: AppWeatherService

    @State private var weatherSymbol: String?

    var body: some View {
        HStack(spacing: 12) {
            profileImage
                .frame(width: 44, height: 44)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(displayName)
                        .font(.body.weight(.semibold))
                        .lineLimit(1)
                    Spacer()
                    Text(timeString)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                HStack {
                    Text(conversation.lastMessage ?? "Starta en konversation")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                    Spacer()
                    if let symbol = weatherSymbol {
                        Image(systemName: symbol)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding(.vertical, 4)
        .task {
            await loadWeather()
        }
    }

    @ViewBuilder
    private var profileImage: some View {
        if let urlString = otherUser?.photoURL, let url = URL(string: urlString) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().scaledToFill()
                default:
                    initialsCircle
                }
            }
        } else if conversation.isGroup {
            ZStack {
                Circle().fill(Color(.systemGray5))
                Image(systemName: "person.3.fill")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        } else {
            initialsCircle
        }
    }

    private var initialsCircle: some View {
        ZStack {
            Circle().fill(Color(.systemGray5))
            Text(initials(from: displayName))
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
        }
    }

    private func initials(from name: String) -> String {
        let parts = name.split(separator: " ")
        let letters = parts.prefix(2).compactMap { $0.first.map { String($0) } }
        return letters.joined().uppercased()
    }

    private func loadWeather() async {
        guard let lat = otherUser?.cityLatitude,
              let lon = otherUser?.cityLongitude else { return }
        let weather = try? await weatherService.currentWeather(latitude: lat, longitude: lon)
        weatherSymbol = weather?.symbolName
    }
}
