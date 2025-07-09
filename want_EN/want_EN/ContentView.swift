import SwiftUI

struct MainTabView: View {
    @StateObject private var personaManager = PersonaManager.shared
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Chat tab - using ChatRoomListView
            ChatRoomListView()
                .tabItem {
                    Image(systemName: "bubble.left.and.bubble.right")
                    Text("Chat")
                }
                .tag(0)
            
            // AI tab
            AIView()
                .tabItem {
                    Image(systemName: "brain.head.profile")
                    Text("AI")
                }
                .tag(1)
            
            // People tab
            PersonaListView()
                .tabItem {
                    Image(systemName: "person.2")
                    Text("People")
                }
                .tag(2)
            
            // Settings tab
            SettingsView()
                .tabItem {
                    Image(systemName: "gearshape")
                    Text("Settings")
                }
                .tag(3)
        }
    }
}

// Legacy ChatListView is removed or renamed
// Using ChatRoomListView instead, so no longer needed

// MARK: - Preview

struct MainTabView_Previews: PreviewProvider {
    static var previews: some View {
        MainTabView()
    }
}
