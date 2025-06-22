import Foundation

struct ChatRoom: Identifiable, Codable, Equatable {
    let id: String
    let personaId: String
    var personaName: String
    var personaAvatar: String?
    var lastMessage: String?
    var lastMessageDate: Date?
    var unreadCount: Int
    var isPinned: Bool
    var isArchived: Bool
    var createdDate: Date
    
    init(
        id: String = UUID().uuidString,
        personaId: String,
        personaName: String,
        personaAvatar: String? = nil,
        lastMessage: String? = nil,
        lastMessageDate: Date? = nil,
        unreadCount: Int = 0,
        isPinned: Bool = false,
        isArchived: Bool = false,
        createdDate: Date = Date()
    ) {
        self.id = id
        self.personaId = personaId
        self.personaName = personaName
        self.personaAvatar = personaAvatar
        self.lastMessage = lastMessage
        self.lastMessageDate = lastMessageDate
        self.unreadCount = unreadCount
        self.isPinned = isPinned
        self.isArchived = isArchived
        self.createdDate = createdDate
    }
    
    // UserPersonaから ChatRoom を作成
    init(from persona: UserPersona) {
        self.id = UUID().uuidString
        self.personaId = persona.id
        self.personaName = persona.name
        self.personaAvatar = persona.customization.avatarEmoji
        self.lastMessage = nil
        self.lastMessageDate = nil
        self.unreadCount = 0
        self.isPinned = false
        self.isArchived = false
        self.createdDate = Date()
    }
    
    // Equatable適合
    static func == (lhs: ChatRoom, rhs: ChatRoom) -> Bool {
        return lhs.id == rhs.id
    }
    
    // 表示用のプロパティ
    var displayLastMessage: String {
        return lastMessage ?? "新しいトークルーム"
    }
    
    var hasUnreadMessages: Bool {
        return unreadCount > 0
    }
    
    var formattedLastMessageDate: String {
        guard let date = lastMessageDate else { return "" }
        
        let formatter = DateFormatter()
        let calendar = Calendar.current
        
        if calendar.isToday(date) {
            formatter.timeStyle = .short
            return formatter.string(from: date)
        } else if calendar.isYesterday(date) {
            return "昨日"
        } else {
            formatter.dateStyle = .short
            return formatter.string(from: date)
        }
    }
}

// MARK: - ChatRoom Manager

class ChatRoomManager: ObservableObject {
    @Published var chatRooms: [ChatRoom] = []
    @Published var currentRoom: ChatRoom?
    
    private let userDefaults = UserDefaults.standard
    private let chatRoomsKey = "saved_chat_rooms"
    
    init() {
        loadChatRooms()
        print("💬 ChatRoomManager初期化完了")
    }
    
    // MARK: - Public Methods
    
    func createChatRoom(for persona: UserPersona) -> ChatRoom {
        // 既存のチャットルームがあるかチェック
        if let existingRoom = chatRooms.first(where: { $0.personaId == persona.id }) {
            return existingRoom
        }
        
        let newRoom = ChatRoom(from: persona)
        chatRooms.append(newRoom)
        saveChatRooms()
        
        print("🆕 新しいチャットルーム作成: \(persona.name)")
        return newRoom
    }
    
    func deleteChatRoom(_ room: ChatRoom) {
        chatRooms.removeAll { $0.id == room.id }
        saveChatRooms()
        print("🗑️ チャットルーム削除: \(room.personaName)")
    }
    
    func pinChatRoom(_ room: ChatRoom) {
        if let index = chatRooms.firstIndex(where: { $0.id == room.id }) {
            chatRooms[index].isPinned.toggle()
            saveChatRooms()
            print("📌 チャットルームピン留め切り替え: \(room.personaName)")
        }
    }
    
    func archiveChatRoom(_ room: ChatRoom) {
        if let index = chatRooms.firstIndex(where: { $0.id == room.id }) {
            chatRooms[index].isArchived.toggle()
            saveChatRooms()
            print("📁 チャットルームアーカイブ切り替え: \(room.personaName)")
        }
    }
    
    func markRoomAsRead(_ room: ChatRoom) {
        if let index = chatRooms.firstIndex(where: { $0.id == room.id }) {
            chatRooms[index].unreadCount = 0
            saveChatRooms()
        }
    }
    
    func updateLastMessage(_ room: ChatRoom, message: String) {
        if let index = chatRooms.firstIndex(where: { $0.id == room.id }) {
            chatRooms[index].lastMessage = message
            chatRooms[index].lastMessageDate = Date()
            saveChatRooms()
        }
    }
    
    func searchChatRooms(_ searchText: String) -> [ChatRoom] {
        if searchText.isEmpty {
            return chatRooms.filter { !$0.isArchived }
        } else {
            return chatRooms.filter { room in
                !room.isArchived && (
                    room.personaName.localizedCaseInsensitiveContains(searchText) ||
                    room.lastMessage?.localizedCaseInsensitiveContains(searchText) == true
                )
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func saveChatRooms() {
        do {
            let data = try JSONEncoder().encode(chatRooms)
            userDefaults.set(data, forKey: chatRoomsKey)
            print("💾 チャットルーム保存完了: \(chatRooms.count)件")
        } catch {
            print("❌ チャットルーム保存エラー: \(error)")
        }
    }
    
    private func loadChatRooms() {
        guard let data = userDefaults.data(forKey: chatRoomsKey) else {
            print("📱 保存されたチャットルームなし")
            return
        }
        
        do {
            chatRooms = try JSONDecoder().decode([ChatRoom].self, from: data)
            print("📱 チャットルーム読み込み完了: \(chatRooms.count)件")
        } catch {
            print("❌ チャットルーム読み込みエラー: \(error)")
            chatRooms = []
        }
    }
}
