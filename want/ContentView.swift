import SwiftUI

struct MainTabView: View {
    @StateObject private var personaManager = PersonaManager.shared
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // チャットタブ - ChatRoomListViewを使用
            ChatRoomListView()
                .tabItem {
                    Image(systemName: "bubble.left.and.bubble.right")
                    Text("チャット")
                }
                .tag(0)
            
            // AIタブ
            AIView()
                .tabItem {
                    Image(systemName: "brain.head.profile")
                    Text("AI")
                }
                .tag(1)
            
            // 人物タブ
            PersonaListView()
                .tabItem {
                    Image(systemName: "person.2")
                    Text("人物")
                }
                .tag(2)
            
            // 設定タブ
            SettingsView()
                .tabItem {
                    Image(systemName: "gearshape")
                    Text("設定")
                }
                .tag(3)
        }
    }
}

// 旧来のChatListViewは削除または名前変更
// ChatRoomListViewを使用するようになったため不要

// MARK: - Preview

struct MainTabView_Previews: PreviewProvider {
    static var previews: some View {
        MainTabView()
    }
}
