import SwiftUI

struct ChatRoomListView: View {
    @StateObject private var personaManager = PersonaManager.shared
    @StateObject private var personaLoader = PersonaLoader.shared
    @StateObject private var chatViewModel = ChatViewModel()
    @State private var searchText = ""
    @State private var selectedPersona: UserPersona?
    @State private var showingSubscriptionView = false
    @State private var navigationPath = NavigationPath()  // ✅ NavigationPathを追加
    
    var filteredPersonas: [UserPersona] {
        if searchText.isEmpty {
            return personaManager.personas
        } else {
            return personaManager.personas.filter { persona in
                persona.name.localizedCaseInsensitiveContains(searchText) ||
                persona.relationship.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        NavigationStack(path: $navigationPath) {  // ✅ NavigationStackを使用
            VStack(spacing: 0) {
                // 検索バー
                searchBar
                
                // AI設定バナー（AIが無効な場合のみ表示）
                if !isAIConfigured {
                    aiSetupBanner
                }
                
                if personaManager.personas.isEmpty {
                    // 空の状態
                    emptyStateView
                } else {
                    // チャットリスト
                    chatListContent
                }
            }
            .navigationTitle("トーク")
            .navigationBarTitleDisplayMode(.large)
            .navigationDestination(for: ChatDestination.self) { destination in  // ✅ NavigationDestinationを使用
                ChatView(isAIMode: destination.isAIMode, persona: destination.persona)
            }
        }
        .sheet(isPresented: $showingSubscriptionView) {
            SubscriptionView()
        }
    }
    
    // MARK: - Search Bar
    
    private var searchBar: some View {
        HStack {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                
                TextField("トークを検索", text: $searchText)
                    .textFieldStyle(PlainTextFieldStyle())
                
                if !searchText.isEmpty {
                    Button(action: {
                        searchText = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(.systemGray6))
            .cornerRadius(10)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
    }
    
    // MARK: - AI Setup Banner
    
    private var aiSetupBanner: some View {
        Button(action: {
            showingSubscriptionView = true
        }) {
            HStack {
                Image(systemName: "brain.head.profile")
                    .font(.title2)
                    .foregroundColor(.blue)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("AI機能を有効にする")
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text("サブスクリプションを開始してAI会話を楽しもう")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.blue)
                    .font(.caption)
                    .fontWeight(.semibold)
            }
            .padding()
            .background(
                LinearGradient(
                    colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.05)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 0)
                    .stroke(Color.blue.opacity(0.3), lineWidth: 0.5)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            VStack(spacing: 8) {
                Text("チャットを始めましょう")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text("「人物」タブでペルソナを作成すると\nチャットができるようになります")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
        }
        .padding(.horizontal)
    }
    
    // MARK: - Chat List Content
    
    private var chatListContent: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(filteredPersonas) { persona in
                    ChatRoomItemView(
                        persona: persona,
                        chatViewModel: chatViewModel,
                        onTap: {
                            // ✅ NavigationPathを使った確実な画面遷移
                            print("🚀 チャット開始: \(persona.name)")
                            let destination = ChatDestination(persona: persona, isAIMode: false)
                            navigationPath.append(destination)
                        }
                    )
                    
                    if persona.id != filteredPersonas.last?.id {
                        Divider()
                            .padding(.leading, 80)
                    }
                }
            }
            .padding(.top, 8)
        }
    }
    
    // MARK: - Computed Properties
    
    private var isAIConfigured: Bool {
        let config = AIConfigManager.shared.currentConfig
        return config.isAIEnabled
    }
}

// ✅ NavigationDestination用のデータ構造
struct ChatDestination: Hashable {
    let persona: UserPersona
    let isAIMode: Bool
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(persona.id)
        hasher.combine(isAIMode)
    }
    
    static func == (lhs: ChatDestination, rhs: ChatDestination) -> Bool {
        return lhs.persona.id == rhs.persona.id && lhs.isAIMode == rhs.isAIMode
    }
}

// MARK: - Supporting Views

struct ChatRoomItemView: View {
    let persona: UserPersona
    let chatViewModel: ChatViewModel
    let onTap: () -> Void
    
    @State private var lastMessage: String = ""
    @State private var messageCount: Int = 0
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // アバター
                AvatarView(
                    persona: persona,
                    size: 50
                )
                
                // チャット情報
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(persona.name)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        if !lastMessage.isEmpty {
                            Text(formatTime(Date()))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    HStack {
                        Text(lastMessage.isEmpty ? "新しい会話を始めよう" : lastMessage)
                            .font(.subheadline)
                            .foregroundColor(lastMessage.isEmpty ? .secondary : .primary)
                            .lineLimit(1)
                        
                        Spacer()
                        
                        // メッセージ数バッジ
                        if messageCount > 0 {
                            Text("\(messageCount)")
                                .font(.caption2)
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.blue)
                                .cornerRadius(8)
                        }
                    }
                    
                    // 性格・関係性の表示
                    HStack {
                        Text(persona.relationship)
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.1))
                            .foregroundColor(.blue)
                            .cornerRadius(4)
                        
                        if let firstPersonality = persona.personality.first {
                            Text(firstPersonality)
                                .font(.caption)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.green.opacity(0.1))
                                .foregroundColor(.green)
                                .cornerRadius(4)
                        }
                        
                        Text(persona.mood.emoji)
                            .font(.caption)
                        
                        Spacer()
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .onAppear {
            loadChatInfo()
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func loadChatInfo() {
        // チャット情報を読み込み
        messageCount = chatViewModel.getMessageCount(for: persona)
        
        if let last = chatViewModel.getLastMessage(for: persona) {
            lastMessage = String(last.content.prefix(30))
        }
    }
}

// MARK: - Preview

struct ChatRoomListView_Previews: PreviewProvider {
    static var previews: some View {
        ChatRoomListView()
    }
}
