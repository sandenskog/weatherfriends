import SwiftUI

struct ProfileView: View {
    let uid: String
    @Environment(AuthManager.self) private var authManager
    @Environment(UserService.self) private var userService
    @Environment(InviteService.self) private var inviteService
    @State private var viewModel = ProfileViewModel()
    @State private var showEditProfile = false
    @State private var showDeleteConfirmation = false
    @State private var isDeletingAccount = false
    @State private var showReauthAlert = false
    @State private var deleteError: String?
    @State private var inviteURL: URL?
    @State private var isGeneratingInvite = false

    private var isOwnProfile: Bool {
        authManager.currentUser?.id == uid
    }

    var body: some View {
        VStack(spacing: 0) {
            // Drag-indikator (visas av systemet via presentationDragIndicator)
            Spacer().frame(height: 8)

            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let user = viewModel.user {
                ScrollView {
                    VStack(spacing: 20) {
                        // Profilbild
                        profileImageView(user: user)
                            .padding(.top, 24)

                        // Namn och stad
                        VStack(spacing: 6) {
                            Text(user.displayName)
                                .font(.title2)
                                .fontWeight(.semibold)

                            if !user.city.isEmpty {
                                Label(user.city, systemImage: "location.fill")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        // Redigera-knapp (visas bara för egen profil)
                        if isOwnProfile {
                            Button {
                                showEditProfile = true
                            } label: {
                                Label("Edit profile", systemImage: "pencil")
                                    .font(.subheadline.weight(.medium))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(Color(.systemGray6))
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                            }
                            .padding(.horizontal)

                            // Share invite link
                            if let inviteURL {
                                ShareLink(item: inviteURL) {
                                    Label("Share my invite link", systemImage: "square.and.arrow.up")
                                        .font(.subheadline.weight(.medium))
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 10)
                                        .background(Color(.systemGray6))
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                }
                                .padding(.horizontal)
                            } else {
                                BubblePopButton(
                                    title: "Generate invite link",
                                    action: { Task { await generateInvite() } },
                                    isLoading: isGeneratingInvite
                                )
                                .frame(maxWidth: .infinity)
                                .padding(.horizontal)
                            }

                            // Konto-radering
                            Button(role: .destructive) {
                                showDeleteConfirmation = true
                            } label: {
                                if isDeletingAccount {
                                    ProgressView()
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 10)
                                } else {
                                    Label("Radera konto", systemImage: "trash")
                                        .font(.subheadline.weight(.medium))
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 10)
                                }
                            }
                            .disabled(isDeletingAccount)
                            .padding(.horizontal)
                            .padding(.top, 8)
                        }

                        Spacer(minLength: 32)
                    }
                }
            } else if let error = viewModel.errorMessage {
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                    Text(error)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .task {
            await viewModel.loadProfile(uid: uid, userService: userService)
        }
        .alert("Radera konto?", isPresented: $showDeleteConfirmation) {
            Button("Radera", role: .destructive) {
                Task { await performDeleteAccount() }
            }
            Button("Avbryt", role: .cancel) {}
        } message: {
            Text("Ditt konto och all din data raderas permanent. Åtgärden kan inte ångras.")
        }
        .alert("Inloggning krävs", isPresented: $showReauthAlert) {
            Button("Logga in igen") {
                Task {
                    do {
                        try await authManager.reauthenticate()
                        await performDeleteAccount()
                    } catch {
                        deleteError = error.localizedDescription
                    }
                }
            }
            Button("Avbryt", role: .cancel) {}
        } message: {
            Text("Av säkerhetsskäl behöver du logga in igen innan kontot kan raderas.")
        }
        .alert("Fel", isPresented: Binding(
            get: { deleteError != nil },
            set: { if !$0 { deleteError = nil } }
        )) {
            Button("OK") { deleteError = nil }
        } message: {
            Text(deleteError ?? "")
        }
        .sheet(isPresented: $showEditProfile) {
            // Ladda om profilen efter redigering
            Task { await viewModel.loadProfile(uid: uid, userService: userService) }
        } content: {
            EditProfileView(uid: uid)
                .environment(authManager)
                .environment(userService)
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }

    private func profileImageView(user: AppUser) -> some View {
        AvatarView(displayName: user.displayName, temperatureCelsius: nil, size: 100, photoURL: user.photoURL)
    }

    private func generateInvite() async {
        isGeneratingInvite = true
        defer { isGeneratingInvite = false }
        do {
            let token = try await inviteService.createInviteToken(for: uid, userService: userService)
            inviteURL = inviteService.inviteURL(token: token)
        } catch {
            deleteError = error.localizedDescription
        }
    }

    private func performDeleteAccount() async {
        isDeletingAccount = true
        defer { isDeletingAccount = false }
        do {
            try await authManager.deleteAccount()
            // authState sätts till .unauthenticated av deleteAccount() ->
            // AppRouter navigerar automatiskt till LoginView
        } catch {
            if case DeleteAccountError.requiresRecentLogin = error {
                showReauthAlert = true
            } else {
                deleteError = error.localizedDescription
            }
        }
    }
}

#Preview {
    Text("Preview")
        .sheet(isPresented: .constant(true)) {
            ProfileView(uid: "preview-uid")
                .environment(AuthManager())
                .environment(UserService())
                .environment(InviteService())
        }
}
