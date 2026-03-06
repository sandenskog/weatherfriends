import SwiftUI

struct NewConversationSheet: View {
    @Environment(ChatService.self) private var chatService
    @Environment(AuthManager.self) private var authManager
    @Environment(FriendService.self) private var friendService
    @Environment(\.dismiss) private var dismiss

    var onConversationCreated: (String) -> Void

    @State private var friends: [Friend] = []
    @State private var selectedFriendIds: Set<String> = Set()
    @State private var searchText = ""
    @State private var groupName = ""
    @State private var isCreating = false
    @State private var isGroupMode = false
    @State private var errorMessage: String?

    private var currentUid: String {
        authManager.currentUser?.id ?? ""
    }

    private var filteredFriends: [Friend] {
        if searchText.isEmpty {
            return friends
        }
        return friends.filter {
            $0.displayName.localizedCaseInsensitiveContains(searchText) ||
            $0.city.localizedCaseInsensitiveContains(searchText)
        }
    }

    private var canCreateGroup: Bool {
        selectedFriendIds.count >= 2
    }

    var body: some View {
        NavigationStack {
            Form {
                // Grupp-toggle
                Section {
                    Toggle("Skapa grupp", isOn: $isGroupMode.animation())
                    if isGroupMode {
                        TextField("Gruppnamn (valfritt)", text: $groupName)
                    }
                }

                // Sökfält
                Section {
                    TextField("Sök vänner...", text: $searchText)
                        .textInputAutocapitalization(.never)
                }

                // Vänlista
                Section {
                    if friends.isEmpty {
                        Text("Inga vänner ännu")
                            .foregroundStyle(.secondary)
                    } else if filteredFriends.isEmpty {
                        Text("Inga vänner matchar sökningen")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(filteredFriends) { friend in
                            friendRow(friend: friend)
                        }
                    }
                } header: {
                    Text(isGroupMode ? "Välj deltagare" : "Välj vän")
                }
            }
            .navigationTitle("Ny konversation")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Avbryt") {
                        dismiss()
                    }
                }
                if isGroupMode {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Skapa grupp") {
                            Task { await createGroup() }
                        }
                        .fontWeight(.semibold)
                        .disabled(!canCreateGroup || isCreating)
                    }
                }
            }
            .overlay {
                if isCreating {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(.ultraThinMaterial)
                }
            }
            .alert("Fel", isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage ?? "")
            }
            .task {
                await loadFriends()
            }
        }
    }

    // MARK: - Vän-rad

    @ViewBuilder
    private func friendRow(friend: Friend) -> some View {
        if isGroupMode {
            // Multi-select med checkbox
            Button {
                toggleSelection(friend: friend)
            } label: {
                HStack(spacing: 12) {
                    profileImage(for: friend)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(friend.displayName)
                            .font(.body)
                            .foregroundStyle(.primary)
                        Text(friend.city)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    if let uid = friend.authUid, selectedFriendIds.contains(uid) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.blue)
                    } else {
                        Image(systemName: "circle")
                            .foregroundStyle(.secondary)
                    }
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        } else {
            // 1-till-1: tryck direkt
            Button {
                Task { await openDirectConversation(with: friend) }
            } label: {
                HStack(spacing: 12) {
                    profileImage(for: friend)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(friend.displayName)
                            .font(.body)
                            .foregroundStyle(.primary)
                        Text(friend.city)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .foregroundStyle(.secondary)
                        .font(.caption)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
    }

    private func profileImage(for friend: Friend) -> some View {
        AvatarView(
            displayName: friend.displayName,
            temperatureCelsius: nil,
            size: 36,
            photoURL: friend.photoURL
        )
    }

    // MARK: - Actions

    private func toggleSelection(friend: Friend) {
        guard let authUid = friend.authUid else { return }
        if selectedFriendIds.contains(authUid) {
            selectedFriendIds.remove(authUid)
        } else {
            selectedFriendIds.insert(authUid)
        }
    }

    private func loadFriends() async {
        guard !currentUid.isEmpty else { return }
        friends = (try? await friendService.fetchFriends(uid: currentUid)) ?? []
    }

    private func openDirectConversation(with friend: Friend) async {
        guard let friendAuthUid = friend.authUid, !currentUid.isEmpty else {
            errorMessage = "Den här vännen har inget konto i appen än."
            return
        }
        isCreating = true
        defer { isCreating = false }
        do {
            let conversationId = try await chatService.getOrCreateDirectConversation(
                currentUid: currentUid,
                friendUid: friendAuthUid
            )
            onConversationCreated(conversationId)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func createGroup() async {
        guard !currentUid.isEmpty, canCreateGroup else { return }
        isCreating = true
        defer { isCreating = false }
        let participantIds = Array(selectedFriendIds)
        let name = groupName.trimmingCharacters(in: .whitespacesAndNewlines)
        do {
            let conversationId = try await chatService.createGroupConversation(
                creatorUid: currentUid,
                participantUids: participantIds,
                groupName: name.isEmpty ? nil : name
            )
            onConversationCreated(conversationId)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
