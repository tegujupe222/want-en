import SwiftUI

struct ChatRoomListView: View {
    @StateObject private var personaManager = PersonaManager.shared
    @StateObject private var personaLoader = PersonaLoader.shared
    @StateObject private var chatViewModel = ChatViewModel()
    @State private var searchText = ""
    @State private var selectedPersona: UserPersona?
    @State private var showingSubscriptionView = false
    @State private var navigationPath = NavigationPath()
    
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
        NavigationSplitView {
            // Sidebar
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
                    chatListSidebar
                }
            }
            .navigationTitle("Chats")
        } detail: {
            // Detail view
            if let selected = selectedPersona {
                ChatView(isAIMode: false, persona: selected, chatViewModel: chatViewModel)
            } else {
                Text("Select a chat from the sidebar")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .navigationSplitViewStyle(.balanced)
        .sheet(isPresented: $showingSubscriptionView) {
            SubscriptionView()
        }
        .ignoresSafeArea(.all, edges: .all)
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
    
    // MARK: - Chat List Sidebar
    
    private var chatListSidebar: some View {
        List(filteredPersonas, id: \.id, selection: $selectedPersona) { persona in
            ChatSidebarItemView(
                persona: persona,
                onTap: {
                    selectedPersona = persona
                }
            )
        }
        .listStyle(SidebarListStyle())
    }
    
    // MARK: - Computed Properties
    
    private var isAIConfigured: Bool {
        let config = AIConfigManager.shared.currentConfig
        return config.isAIEnabled
    }
}

// MARK: - Supporting Views

struct ChatSidebarItemView: View {
    let persona: UserPersona
    let onTap: () -> Void
    
    @State private var lastMessage: String = ""
    @State private var messageCount: Int = 0
    
    private var messages: [ChatMessage] {
        let key = "chat_messages_\(persona.id)"
        if let data = UserDefaults.standard.data(forKey: key) {
            do {
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .secondsSince1970
                return try decoder.decode([ChatMessage].self, from: data)
            } catch {
                print("❌ Failed to load messages for display: \(error)")
                return []
            }
        }
        return []
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Avatar
            AvatarView(persona: persona, size: 40)
            
            // Chat info
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(persona.name)
                        .font(.body)
                        .fontWeight(.medium)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    if !lastMessage.isEmpty {
                        Text(formatTime(Date()))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                
                HStack {
                    Text(lastMessage.isEmpty ? "Start a new conversation" : lastMessage)
                        .font(.caption)
                        .foregroundColor(lastMessage.isEmpty ? .secondary : .primary)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    // Message count badge
                    if messageCount > 0 {
                        Text("\(messageCount)")
                            .font(.caption2)
                            .foregroundColor(.white)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(Color.blue)
                            .cornerRadius(6)
                    }
                }
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
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
        // Load chat info from UserDefaults
        let key = "chat_messages_\(persona.id)"
        if let data = UserDefaults.standard.data(forKey: key) {
            do {
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .secondsSince1970
                let messages = try decoder.decode([ChatMessage].self, from: data)
                messageCount = messages.count
                lastMessage = messages.last?.content ?? "No messages yet"
            } catch {
                print("❌ Failed to load chat info: \(error)")
                messageCount = 0
                lastMessage = "No messages yet"
            }
        } else {
            messageCount = 0
            lastMessage = "No messages yet"
        }
    }
}

// MARK: - Preview

struct ChatRoomListView_Previews: PreviewProvider {
    static var previews: some View {
        ChatRoomListView()
    }
}
