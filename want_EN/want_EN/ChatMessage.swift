import Foundation

// ✅ UUID永続化の修正版
struct ChatMessage: Identifiable, Codable, Equatable {
    let id: UUID
    let content: String
    let isFromUser: Bool
    let timestamp: Date
    let emotion: String?
    let emotionTrigger: String?
    
    // ✅ 修正: initでUUIDを明示的に設定
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
    
    // ✅ 感情検出付きのコンビニエンスイニシャライザー
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
            // ボットメッセージの場合、感情を自動検出
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
    
    // ✅ Codableのためのカスタムキー（すべてのプロパティを含む）
    private enum CodingKeys: String, CodingKey {
        case id, content, isFromUser, timestamp, emotion, emotionTrigger
    }
    
    // ✅ カスタムエンコーダー（デバッグ用）
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(content, forKey: .content)
        try container.encode(isFromUser, forKey: .isFromUser)
        try container.encode(timestamp, forKey: .timestamp)
        try container.encodeIfPresent(emotion, forKey: .emotion)
        try container.encodeIfPresent(emotionTrigger, forKey: .emotionTrigger)
    }
    
    // ✅ カスタムデコーダー（デバッグ用）
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        content = try container.decode(String.self, forKey: .content)
        isFromUser = try container.decode(Bool.self, forKey: .isFromUser)
        timestamp = try container.decode(Date.self, forKey: .timestamp)
        emotion = try container.decodeIfPresent(String.self, forKey: .emotion)
        emotionTrigger = try container.decodeIfPresent(String.self, forKey: .emotionTrigger)
    }
    
    // ✅ Equatableの実装
    static func == (lhs: ChatMessage, rhs: ChatMessage) -> Bool {
        return lhs.id == rhs.id
    }
}

// MARK: - Extensions

extension ChatMessage {
    // ✅ 表示用のプロパティ
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
    
    // ✅ 感情情報の取得
    var emotionInfo: EmotionTrigger? {
        guard let emotionTrigger = emotionTrigger else { return nil }
        return EmotionTrigger.defaultTriggers.first { $0.emotion == emotionTrigger }
    }
    
    var hasEmotion: Bool {
        return emotion != nil || emotionTrigger != nil
    }
    
    // ✅ メッセージの分析
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
    
    // ✅ 感情強度の計算
    var emotionalIntensity: Int {
        return EmotionTrigger.getEmotionStrength(for: content)
    }
    
    // ✅ メッセージのカテゴリ分類
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
    
    // ✅ 感情検出メソッド
    func detectEmotions() -> [EmotionTrigger] {
        return EmotionTrigger.findAllTriggers(for: content)
    }
    
    func getPrimaryEmotion() -> EmotionTrigger? {
        return EmotionTrigger.findTrigger(for: content)
    }
    
    // ✅ コピーメソッド
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
            return "質問"
        case .emotional:
            return "感情的"
        case .brief:
            return "簡潔"
        case .detailed:
            return "詳細"
        case .normal:
            return "通常"
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
    // ✅ よく使われるメッセージの生成
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
            content: "申し訳ありません。\(error)",
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
        case let r where r.contains("家族") || r.contains("母") || r.contains("父"):
            return "こんにちは！\(name)よ。元気にしてた？何か話したいことはある？"
        case let r where r.contains("友"):
            return "やあ！久しぶり〜！最近どう？何か面白いことあった？"
        case let r where r.contains("恋人"):
            return "おかえり♪ 今日はどんな一日だった？聞かせて！"
        case let r where r.contains("先生"):
            return "こんにちは。今日も一日お疲れさまでした。何かお話ししたいことはありますか？"
        default:
            let catchphrase = persona.catchphrases.first ?? ""
            if catchphrase.isEmpty {
                return "こんにちは！\(name)です。今日はよろしくお願いします！"
            } else {
                return "\(catchphrase) こんにちは！\(name)です。お話ししましょう！"
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
