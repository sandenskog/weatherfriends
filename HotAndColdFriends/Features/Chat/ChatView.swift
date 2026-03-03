import SwiftUI
import FirebaseFirestore

struct ChatView: View {
    let conversationId: String

    @Environment(ChatService.self) private var chatService
    @Environment(AuthManager.self) private var authManager
    @Environment(AppWeatherService.self) private var weatherService

    @State private var viewModel = ChatViewModel()
    @State private var showWeatherStickerPicker = false
    @State private var showBlockConfirmation = false
    @State private var userToBlock: String?

    private var currentUid: String {
        authManager.currentUser?.id ?? ""
    }

    var body: some View {
        VStack(spacing: 0) {
            // Väder-header
            let others = viewModel.otherParticipants(currentUid: currentUid)
            if !others.isEmpty {
                WeatherHeaderView(participants: others)
                    .environment(weatherService)
                Divider()
            }

            // Meddelandelista
            messageList

            Divider()

            // Inmatningsfält
            messageInputBar
        }
        .navigationTitle(viewModel.conversationTitle(currentUid: currentUid))
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.load(conversationId: conversationId, chatService: chatService)
        }
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

    // MARK: - Meddelandelista

    private var messageList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 6) {
                    ForEach(chatService.messages) { message in
                        ChatBubbleView(
                            message: message,
                            isCurrentUser: message.senderId == currentUid,
                            senderName: senderName(for: message),
                            onReport: {
                                reportMessage(message)
                            },
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
                    withAnimation {
                        proxy.scrollTo(lastId, anchor: .bottom)
                    }
                }
            }
        }
    }

    // MARK: - Inmatningsfält

    private var messageInputBar: some View {
        @Bindable var vm = viewModel
        return HStack(spacing: 8) {
            // Väder-sticker-knapp
            Button {
                showWeatherStickerPicker = true
            } label: {
                Image(systemName: "cloud.sun")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }

            TextField("Skriv ett meddelande...", text: $vm.messageText, axis: .vertical)
                .textFieldStyle(.plain)
                .lineLimit(1...4)
                .submitLabel(.send)
                .onSubmit {
                    sendMessage()
                }

            // Skicka-knapp
            Button {
                sendMessage()
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.title2)
                    .foregroundStyle(viewModel.messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .gray : .blue)
            }
            .disabled(viewModel.messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
    }

    // MARK: - Actions

    private func sendMessage() {
        Task {
            await viewModel.send(chatService: chatService, senderId: currentUid)
        }
    }

    private func reportMessage(_ message: ChatMessage) {
        guard let msgId = message.id,
              let convId = viewModel.conversation?.id else { return }
        let report = Report(
            id: nil,
            reporterUid: currentUid,
            reportedUid: message.senderId,
            messageId: msgId,
            conversationId: convId,
            reason: "reported_by_user",
            createdAt: nil
        )
        Task {
            try? await chatService.reportMessage(report: report)
        }
    }

    private func blockUser(uid: String) {
        Task {
            try? await chatService.blockUser(uid: currentUid, blockedUid: uid)
        }
    }

    private func senderName(for message: ChatMessage) -> String? {
        guard let conversation = viewModel.conversation, conversation.isGroup else { return nil }
        return viewModel.participantUsers[message.senderId]?.displayName
    }
}
