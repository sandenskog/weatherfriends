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

    private var profileImageView: some View {
        AvatarView(
            displayName: friend.displayName,
            temperatureCelsius: nil,
            size: 100,
            photoURL: friend.photoURL
        )
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
