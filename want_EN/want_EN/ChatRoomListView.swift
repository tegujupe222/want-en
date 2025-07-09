import SwiftUI

struct ChatRoomListView: View {
    @StateObject private var personaManager = PersonaManager.shared
    @StateObject private var personaLoader = PersonaLoader.shared
    @StateObject private var chatViewModel = ChatViewModel()
    @State private var searchText = ""
    @State private var selectedPersona: UserPersona?
    @State private var showingSubscriptionView = false
    @State private var navigationPath = NavigationPath()  // ✅ Added NavigationPath
    
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
        NavigationStack(path: $navigationPath) {  // ✅ Using NavigationStack
            VStack(spacing: 0) {
                // Search bar
                searchBar
                
                // AI setup banner (only shown when AI is disabled)
                if !isAIConfigured {
                    aiSetupBanner
                }
                
                if personaManager.personas.isEmpty {
                    // Empty state
                    emptyStateView
                } else {
                    // Chat list
                    chatListContent
                }
            }
            .navigationTitle("Chats")
            .navigationBarTitleDisplayMode(.large)
            .navigationDestination(for: ChatDestination.self) { destination in  // ✅ Using NavigationDestination
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
                
                TextField("Search chats", text: $searchText)
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
                    Text("Enable AI Features")
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text("Start subscription to enjoy AI conversations")
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
                Text("Start chatting")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text("Create personas in the \"People\" tab\nto start chatting")
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
                            // ✅ Reliable navigation using NavigationPath
                            print("🚀 Starting chat: \(persona.name)")
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

// ✅ Data structure for NavigationDestination
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
                // Avatar
                AvatarView(
                    persona: persona,
                    size: 50
                )
                
                // Chat info
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
                        Text(lastMessage.isEmpty ? "Start a new conversation" : lastMessage)
                            .font(.subheadline)
                            .foregroundColor(lastMessage.isEmpty ? .secondary : .primary)
                            .lineLimit(1)
                        
                        Spacer()
                        
                        // Message count badge
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
                    
                    // Personality and relationship display
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
        // Load chat info
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
