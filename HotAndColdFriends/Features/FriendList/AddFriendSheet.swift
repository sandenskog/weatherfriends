import SwiftUI

struct AddFriendSheet: View {
    let uid: String
    let friendService: FriendService
    let onAdded: () -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(UserService.self) private var userService
    @Environment(InviteService.self) private var inviteService
    @State private var tokenInput = ""
    @State private var isRedeeming = false
    @State private var errorMessage: String?
    @State private var successName: String?
    @State private var showConfetti = false
    @State private var confettiZone: TemperatureZone = .warm
    @State private var inviteToken: String?
    @State private var inviteURL: URL?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // MARK: - Share your invite link
                    VStack(spacing: 12) {
                        if let inviteURL {
                            ShareLink(item: inviteURL) {
                                Label("Invite via Link", systemImage: "square.and.arrow.up")
                                    .font(.subheadline.weight(.medium))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(Color(.systemGray6))
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                            }
                        }
                    }
                    .padding(.top, 8)

                    // MARK: - Divider
                    HStack {
                        Rectangle().frame(height: 1).foregroundStyle(.quaternary)
                        Text("or redeem a friend's link")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Rectangle().frame(height: 1).foregroundStyle(.quaternary)
                    }

                    // MARK: - Explanation
                    VStack(spacing: 12) {
                        Image(systemName: "link.badge.plus")
                            .font(.system(size: 40))
                            .foregroundStyle(.secondary)

                        Text("Add a friend")
                            .font(.title3.weight(.semibold))

                        Text("Ask your friend to share their invite link from their profile, then paste it here.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }

                    // MARK: - Token input
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Invite link or token")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)

                        HStack {
                            TextField("Paste invite link...", text: $tokenInput)
                                .autocorrectionDisabled()
                                .textInputAutocapitalization(.never)

                            Button {
                                pasteFromClipboard()
                            } label: {
                                Image(systemName: "doc.on.clipboard")
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    // MARK: - Success state
                    if let name = successName {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                            Text("You and \(name) are now friends!")
                                .font(.subheadline.weight(.medium))
                            Spacer()
                        }
                        .padding()
                        .background(Color.green.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    // MARK: - Redeem button
                    BubblePopButton(
                        title: "Redeem invite",
                        action: { Task { await redeemInvite() } },
                        isLoading: isRedeeming,
                        isDisabled: !canRedeem
                    )
                    .frame(maxWidth: .infinity)
                }
                .padding()
            }
            .navigationTitle("Add friend")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .alert("Error", isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) {
                Button("OK") { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
            }
            .confettiOverlay(isActive: $showConfetti, zone: confettiZone)
            .task {
                do {
                    let token = try await inviteService.getOrCreateInviteToken(for: uid, userService: userService)
                    inviteURL = inviteService.inviteURL(token: token)
                    inviteToken = token
                } catch {
                    // Non-critical — user can still redeem links manually
                }
            }
        }
    }

    // MARK: - Computed

    private var canRedeem: Bool {
        !extractedToken.isEmpty && successName == nil
    }

    /// Extracts the token from either a full URL or raw token input
    private var extractedToken: String {
        let trimmed = tokenInput.trimmingCharacters(in: .whitespacesAndNewlines)
        // Handle HTTPS Universal Link: https://apps.sandenskog.se/invite/<token>
        if let url = URL(string: trimmed),
           url.host == "apps.sandenskog.se",
           url.pathComponents.count >= 3,
           url.pathComponents[1] == "invite" {
            return url.pathComponents[2]
        }
        // Handle legacy custom scheme: hotandcold://invite/<token>
        if let url = URL(string: trimmed),
           url.scheme == "hotandcold",
           url.host == "invite",
           let token = url.pathComponents.dropFirst().first {
            return token
        }
        // Handle raw token
        return trimmed
    }

    // MARK: - Actions

    private func pasteFromClipboard() {
        if let content = UIPasteboard.general.string {
            tokenInput = content
        }
    }

    private func redeemInvite() async {
        isRedeeming = true
        defer { isRedeeming = false }

        let token = extractedToken
        guard !token.isEmpty else { return }

        do {
            // Look up invite to get sender info for success message and confetti
            guard let invite = try await inviteService.lookupInviteToken(token) else {
                errorMessage = InviteError.invalidToken.localizedDescription
                return
            }

            // Derive confetti zone from sender's city latitude if available
            // (we don't have lat in invite doc, so use default warm zone)
            confettiZone = .warm

            try await inviteService.redeemInvite(
                token: token,
                redeemerUid: uid,
                friendService: friendService,
                userService: userService
            )

            successName = invite.senderDisplayName
            showConfetti = true
            onAdded()

            // Delay dismiss so confetti and success message are visible
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                dismiss()
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
