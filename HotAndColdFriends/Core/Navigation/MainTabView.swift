import SwiftUI

struct MainTabView: View {
    @Binding var openConversationId: String?

    var body: some View {
        TabView {
            NavigationStack {
                FriendListView()
            }
            .tabItem {
                Label("Vänner", systemImage: "person.2")
            }

            NavigationStack {
                ConversationListView(openConversationId: $openConversationId)
            }
            .tabItem {
                Label("Chattar", systemImage: "bubble.left.and.bubble.right")
            }
        }
    }
}
