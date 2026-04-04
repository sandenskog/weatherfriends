import SwiftUI
import FirebaseFirestore

struct ChatView: View {
    let conversationId: String

    @Environment(ChatService.self) private var chatService
    @Environment(AuthManager.self) private var authManager
    @Environment(AppWeatherService.self) private var weatherService

    @State private var viewModel = ChatViewModel()
    @State private var showWeatherStickerPicker = false
    @State private var sendHapticTrigger = false
    @State private var friendSkyMood: SkyMood = .sunny

    private var currentUid: String {
        authManager.currentUser?.id ?? ""
    }

    private var chatTitle: String {
        viewModel.conversationTitle(currentUid: currentUid)
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            // Sky background from friend's weather
            AtmosphereSkyBackground(mood: friendSkyMood)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Floating nav header on sky
                navHeader
                    .padding(.top, 60)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 12)

                // Glass message sheet covering most of screen
                VStack(spacing: 0) {
                    messageList
                    messageInputBar
                }
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                .ignoresSafeArea(edges: .bottom)
            }
        }
        .ignoresSafeArea()
        .toolbar(.hidden, for: .navigationBar)
        .task {
            await viewModel.load(conversationId: conversationId, chatService: chatService)
            await loadFriendWeather()
        }
        .sensoryFeedback(.impact(weight: .light), trigger: sendHapticTrigger)
        .onDisappear {
            chatService.stopListeningToMessages()
        }
        .sheet(isPresented: $showWeatherStickerPicker) {
            WeatherStickerPickerView(
                currentUser: authManager.currentUser,
                otherUsers: viewModel.otherParticipants(currentUid: currentUid),
                weatherService: weatherService
            ) { stickerData in
                showWeatherStickerPicker = false
                Task {
                    await viewModel.sendSticker(data: stickerData, chatService: chatService, senderId: currentUid)
                }
            }
        }
    }

    // MARK: - Nav Header (floating on sky)

    private var navHeader: some View {
        HStack(spacing: 12) {
            // Back button
            Button {
                // navigation is handled by NavigationStack in parent
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Color.atmosphereTextOnSky)
                    .frame(width: 36, height: 36)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
            }

            VStack(alignment: .leading, spacing: 1) {
                Text(chatTitle)
                    .font(.atmosphereCity)
                    .foregroundStyle(Color.atmosphereTextOnSky)
                    .shadow(radius: 3)

                // Show weather for the other participant
                if let other = viewModel.otherParticipants(currentUid: currentUid).first {
                    Text(other.city)
                        .font(.atmosphereFriendCity)
                        .foregroundStyle(Color.atmosphereTextOnSkySecondary)
                        .shadow(radius: 2)
                }
            }

            Spacer()
        }
    }

    // MARK: - Message List

    private var messageList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 6) {
                    ForEach(chatService.messages) { message in
                        ChatBubbleView(
                            message: message,
                            isCurrentUser: message.senderId == currentUid,
                            senderName: senderName(for: message),
                            onReport: { reportMessage(message) },
                            onBlock: message.senderId != currentUid ? {
                                blockUser(uid: message.senderId)
                            } : nil
                        )
                        .id(message.id)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
            }
            .onChange(of: chatService.messages.count) { _, _ in
                if let lastId = chatService.messages.last?.id {
                    withAnimation { proxy.scrollTo(lastId, anchor: .bottom) }
                }
            }
        }
    }

    // MARK: - Input Bar

    private var messageInputBar: some View {
        @Bindable var vm = viewModel
        return HStack(spacing: 10) {
            Button {
                showWeatherStickerPicker = true
            } label: {
                Image(systemName: "cloud.sun")
                    .font(.system(size: 20))
                    .foregroundStyle(.secondary)
            }

            TextField("Skriv ett meddelande...", text: $vm.messageText, axis: .vertical)
                .textFieldStyle(.plain)
                .lineLimit(1...4)
                .submitLabel(.send)
                .onSubmit { sendMessage() }

            Button { sendMessage() } label: {
                let hasText = !viewModel.messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(hasText ? Color.bubblePrimary : Color.secondary)
            }
            .disabled(viewModel.messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .padding(.bottom, 20) // safe area compensation
    }

    // MARK: - Actions

    private func sendMessage() {
        sendHapticTrigger.toggle()
        Task {
            await viewModel.send(chatService: chatService, senderId: currentUid)
        }
    }

    private func reportMessage(_ message: ChatMessage) {
        guard let msgId = message.id, let convId = viewModel.conversation?.id else { return }
        let report = Report(
            id: nil,
            reporterUid: currentUid,
            reportedUid: message.senderId,
            messageId: msgId,
            conversationId: convId,
            reason: "reported_by_user",
            createdAt: nil
        )
        Task { try? await chatService.reportMessage(report: report) }
    }

    private func blockUser(uid: String) {
        Task { try? await chatService.blockUser(uid: currentUid, blockedUid: uid) }
    }

    private func senderName(for message: ChatMessage) -> String? {
        guard let conversation = viewModel.conversation, conversation.isGroup else { return nil }
        return viewModel.participantUsers[message.senderId]?.displayName
    }

    private func loadFriendWeather() async {
        guard let other = viewModel.otherParticipants(currentUid: currentUid).first,
              let lat = other.cityLatitude,
              let lon = other.cityLongitude else { return }
        if let weather = try? await weatherService.currentWeather(latitude: lat, longitude: lon) {
            friendSkyMood = SkyMood.from(symbolName: weather.symbolName, isDaytime: true)
        }
    }
}
