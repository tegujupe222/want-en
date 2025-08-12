import Foundation

// ✅ UUID persistence fix version
struct ChatMessage: Identifiable, Codable, Equatable {
    let id: UUID
    let content: String
    let isFromUser: Bool
    let timestamp: Date
    let emotion: String?
    let emotionTrigger: String?
    
    // ✅ Fix: explicitly set UUID in init
    init(
        id: UUID = UUID(),
        content: String,
        isFromUser: Bool,
        timestamp: Date = Date(),
        emotion: String? = nil,
        emotionTrigger: String? = nil
    ) {
        self.id = id
        self.content = content
        self.isFromUser = isFromUser
        self.timestamp = timestamp
        self.emotion = emotion
        self.emotionTrigger = emotionTrigger
    }
    
    // ✅ Convenience initializer with emotion detection
    init(
        content: String,
        isFromUser: Bool,
        timestamp: Date = Date(),
        detectEmotion: Bool = true
    ) {
        self.id = UUID()
        self.content = content
        self.isFromUser = isFromUser
        self.timestamp = timestamp
        
        if detectEmotion && !isFromUser {
            // Auto-detect emotion for bot messages
            if let trigger = EmotionTrigger.findTrigger(for: content) {
                self.emotion = trigger.emotion
                self.emotionTrigger = trigger.emotion
            } else {
                self.emotion = nil
                self.emotionTrigger = nil
            }
        } else {
            self.emotion = nil
            self.emotionTrigger = nil
        }
    }
    
    // ✅ Custom keys for Codable (include all properties)
    private enum CodingKeys: String, CodingKey {
        case id, content, isFromUser, timestamp, emotion, emotionTrigger
    }
    
    // ✅ Custom encoder (for debugging)
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(content, forKey: .content)
        try container.encode(isFromUser, forKey: .isFromUser)
        try container.encode(timestamp, forKey: .timestamp)
        try container.encodeIfPresent(emotion, forKey: .emotion)
        try container.encodeIfPresent(emotionTrigger, forKey: .emotionTrigger)
    }
    
    // ✅ Custom decoder (for debugging)
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        content = try container.decode(String.self, forKey: .content)
        isFromUser = try container.decode(Bool.self, forKey: .isFromUser)
        timestamp = try container.decode(Date.self, forKey: .timestamp)
        emotion = try container.decodeIfPresent(String.self, forKey: .emotion)
        emotionTrigger = try container.decodeIfPresent(String.self, forKey: .emotionTrigger)
    }
    
    // ✅ Equatable implementation
    static func == (lhs: ChatMessage, rhs: ChatMessage) -> Bool {
        return lhs.id == rhs.id
    }
}

// MARK: - Extensions

extension ChatMessage {
    // ✅ Display properties
    var displayTime: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: timestamp)
    }
    
    var displayDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: timestamp)
    }
    
    var isToday: Bool {
        return Calendar.current.isDateInToday(timestamp)
    }
    
    var isYesterday: Bool {
        return Calendar.current.isDateInYesterday(timestamp)
    }
    
    // ✅ Get emotion information
    var emotionInfo: EmotionTrigger? {
        guard let emotionTrigger = emotionTrigger else { return nil }
        return EmotionTrigger.defaultTriggers.first { $0.emotion == emotionTrigger }
    }
    
    var hasEmotion: Bool {
        return emotion != nil || emotionTrigger != nil
    }
    
    // ✅ Message analysis
    var wordCount: Int {
        return content.components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }.count
    }
    
    var characterCount: Int {
        return content.count
    }
    
    var isShort: Bool {
        return content.count < 20
    }
    
    var isLong: Bool {
        return content.count > 100
    }
    
    // ✅ Calculate emotional intensity
    var emotionalIntensity: Int {
        return EmotionTrigger.getEmotionStrength(for: content)
    }
    
    // ✅ Message category classification
    var messageCategory: MessageCategory {
        if content.contains("？") || content.contains("?") {
            return .question
        } else if emotionalIntensity > 6 {
            return .emotional
        } else if content.count < 10 {
            return .brief
        } else if content.count > 50 {
            return .detailed
        } else {
            return .normal
        }
    }
    
    // ✅ Emotion detection methods
    func detectEmotions() -> [EmotionTrigger] {
        return EmotionTrigger.findAllTriggers(for: content)
    }
    
    func getPrimaryEmotion() -> EmotionTrigger? {
        return EmotionTrigger.findTrigger(for: content)
    }
    
    // ✅ Copy method
    func copy(
        content: String? = nil,
        emotion: String? = nil,
        emotionTrigger: String? = nil
    ) -> ChatMessage {
        return ChatMessage(
            id: self.id,
            content: content ?? self.content,
            isFromUser: self.isFromUser,
            timestamp: self.timestamp,
            emotion: emotion ?? self.emotion,
            emotionTrigger: emotionTrigger ?? self.emotionTrigger
        )
    }
}

// MARK: - Supporting Enums

enum MessageCategory {
    case question
    case emotional
    case brief
    case detailed
    case normal
    
    var description: String {
        switch self {
        case .question:
            return "Question"
        case .emotional:
            return "Emotional"
        case .brief:
            return "Brief"
        case .detailed:
            return "Detailed"
        case .normal:
            return "Normal"
        }
    }
    
    var icon: String {
        switch self {
        case .question:
            return "questionmark.circle"
        case .emotional:
            return "heart.fill"
        case .brief:
            return "text.quote"
        case .detailed:
            return "text.alignleft"
        case .normal:
            return "message"
        }
    }
}

// MARK: - Factory Methods

extension ChatMessage {
    // ✅ Generate commonly used messages
    static func welcomeMessage(for persona: UserPersona) -> ChatMessage {
        let welcomeContent = generateWelcomeContent(for: persona)
        return ChatMessage(
            content: welcomeContent,
            isFromUser: false,
            detectEmotion: true
        )
    }
    
    static func errorMessage(_ error: String) -> ChatMessage {
        return ChatMessage(
            content: "I'm sorry. \(error)",
            isFromUser: false,
            detectEmotion: false
        )
    }
    
    static func systemMessage(_ content: String) -> ChatMessage {
        return ChatMessage(
            content: content,
            isFromUser: false,
            detectEmotion: false
        )
    }
    
    private static func generateWelcomeContent(for persona: UserPersona) -> String {
        let relationship = persona.relationship.lowercased()
        let name = persona.name
        
        switch relationship {
        case let r where r.contains("family") || r.contains("mother") || r.contains("father"):
            return "Hello! I'm \(name). How are you doing? Is there anything you'd like to talk about?"
        case let r where r.contains("friend"):
            return "Hey! Long time no see! How have you been? Any interesting stories?"
        case let r where r.contains("lover"):
            return "Welcome back! ♪ How was your day? Tell me about it!"
        case let r where r.contains("teacher"):
            return "Hello. Thank you for your hard work today. Is there anything you'd like to discuss?"
        default:
            let catchphrase = persona.catchphrases.first ?? ""
            if catchphrase.isEmpty {
                return "Hello! I'm \(name). Nice to meet you today!"
            } else {
                return "\(catchphrase) Hello! I'm \(name). Let's chat!"
            }
        }
    }
}

// MARK: - Debugging Support

extension ChatMessage {
    var debugDescription: String {
        return """
        ChatMessage {
            id: \(id)
            content: "\(content.prefix(50))..."
            isFromUser: \(isFromUser)
            timestamp: \(timestamp)
            emotion: \(emotion ?? "nil")
            emotionTrigger: \(emotionTrigger ?? "nil")
            category: \(messageCategory.description)
            intensity: \(emotionalIntensity)
        }
        """
    }
}
