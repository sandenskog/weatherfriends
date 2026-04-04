import SwiftUI

struct MainTabView: View {
    @Binding var openConversationId: String?
    @Binding var openWeatherAlertFriendId: String?
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            FriendsTabView(openWeatherAlertFriendId: $openWeatherAlertFriendId)
                .tabItem {
                    Label("Vänner", systemImage: "person.2.fill")
                }
                .tag(0)

            // ConversationListView already has its own NavigationStack — don't double-wrap
            ConversationListView(openConversationId: $openConversationId)
                .tabItem {
                    Label("Chattar", systemImage: "bubble.left.and.bubble.right.fill")
                }
                .tag(1)
        }
        .toolbarBackground(.ultraThinMaterial, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
        .tint(.white)
        .onChange(of: openWeatherAlertFriendId) { _, id in
            if id != nil { selectedTab = 0 }
        }
    }
}
