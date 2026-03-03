import SwiftUI

struct FriendProfileView: View {
    let friend: Friend

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 8)

            ScrollView {
                VStack(spacing: 20) {
                    profileImageView
                        .padding(.top, 24)

                    VStack(spacing: 6) {
                        Text(friend.displayName)
                            .font(.title2)
                            .fontWeight(.semibold)

                        if !friend.city.isEmpty {
                            Label(friend.city, systemImage: "location.fill")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Spacer(minLength: 32)
                }
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }

    @ViewBuilder
    private var profileImageView: some View {
        if let urlString = friend.photoURL, let url = URL(string: urlString) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(width: 100, height: 100)
                        .clipShape(Circle())
                case .failure(_), .empty:
                    initialsCircle(name: friend.displayName, size: 100)
                @unknown default:
                    initialsCircle(name: friend.displayName, size: 100)
                }
            }
        } else {
            initialsCircle(name: friend.displayName, size: 100)
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
            FriendProfileView(friend: Friend(
                displayName: "Anna Andersson",
                photoURL: nil,
                city: "Stockholm",
                cityLatitude: 59.33,
                cityLongitude: 18.07,
                isFavorite: false,
                isDemo: false
            ))
        }
}
