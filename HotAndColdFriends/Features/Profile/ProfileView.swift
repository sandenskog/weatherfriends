import SwiftUI

struct ProfileView: View {
    let uid: String
    @Environment(AuthManager.self) private var authManager
    @Environment(UserService.self) private var userService
    @State private var viewModel = ProfileViewModel()
    @State private var showEditProfile = false

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
                                Label("Redigera profil", systemImage: "pencil")
                                    .font(.subheadline.weight(.medium))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(Color(.systemGray6))
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                            }
                            .padding(.horizontal)
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

    @ViewBuilder
    private func profileImageView(user: AppUser) -> some View {
        if let photoURL = user.profileImageURL {
            AsyncImage(url: photoURL) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(width: 100, height: 100)
                        .clipShape(Circle())
                case .failure(_), .empty:
                    initialsCircle(name: user.displayName, size: 100)
                @unknown default:
                    initialsCircle(name: user.displayName, size: 100)
                }
            }
        } else {
            initialsCircle(name: user.displayName, size: 100)
        }
    }

    private func initialsCircle(name: String, size: CGFloat) -> some View {
        ZStack {
            Circle()
                .fill(Color(.systemGray5))
                .frame(width: size, height: size)
            Text(initials(from: name))
                .font(.system(size: size * 0.38, weight: .medium))
                .foregroundStyle(.secondary)
        }
    }

    private func initials(from name: String) -> String {
        let parts = name
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .components(separatedBy: .whitespaces)
            .filter { !$0.isEmpty }
        let first = parts.first?.first.map(String.init) ?? ""
        let last = parts.count > 1 ? (parts.last?.first.map(String.init) ?? "") : ""
        let result = (first + last).uppercased()
        return result.isEmpty ? "?" : result
    }
}

#Preview {
    Text("Preview")
        .sheet(isPresented: .constant(true)) {
            ProfileView(uid: "preview-uid")
                .environment(AuthManager())
                .environment(UserService())
        }
}
