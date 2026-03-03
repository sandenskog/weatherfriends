import SwiftUI

struct MainTabView: View {
    @Binding var openConversationId: String?
    @Binding var openWeatherAlertFriendId: String?
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            FriendsTabView(openWeatherAlertFriendId: $openWeatherAlertFriendId)
                .tabItem {
                    Label("Vänner", systemImage: "person.2")
                }
                .tag(0)

            NavigationStack {
                ConversationListView(openConversationId: $openConversationId)
            }
            .tabItem {
                Label("Chattar", systemImage: "bubble.left.and.bubble.right")
            }
            .tag(1)
        }
        .onChange(of: openWeatherAlertFriendId) { _, id in
            if id != nil { selectedTab = 0 }
        }
    }
}
