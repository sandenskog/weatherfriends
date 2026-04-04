import SwiftUI

struct MainTabView: View {
    @Binding var openConversationId: String?
    @Binding var openWeatherAlertFriendId: String?
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            FriendsTabView(openWeatherAlertFriendId: $openWeatherAlertFriendId)
                .tabItem {
                    Label("Vänner", systemImage: selectedTab == 0 ? "person.2.fill" : "person.2")
                }
                .tag(0)

            NavigationStack {
                ConversationListView(openConversationId: $openConversationId)
            }
            .tabItem {
                Label("Chattar", systemImage: selectedTab == 1
                    ? "bubble.left.and.bubble.right.fill"
                    : "bubble.left.and.bubble.right")
            }
            .tag(1)
        }
        // Let the sky bleed through the tab bar
        .toolbarBackground(.ultraThinMaterial, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
        .tint(.white)
        .onChange(of: openWeatherAlertFriendId) { _, id in
            if id != nil { selectedTab = 0 }
        }
    }
}
