import Foundation

struct EmotionTrigger: Identifiable, Codable {
    let id: UUID
    let emotion: String
    let emoji: String
    let keywords: [String]
    let responses: [String]  // ✅ 追加：応答テキスト
    let followUpQuestions: [String]  // ✅ 追加：フォローアップ質問
    let intensity: Int // 1-10
    
    init(emotion: String,
         emoji: String,
         keywords: [String],
         responses: [String] = [],
         followUpQuestions: [String] = [],
         intensity: Int = 5) {
        self.id = UUID()  // ✅ 修正: initの中でUUIDを生成
        self.emotion = emotion
        self.emoji = emoji
        self.keywords = keywords
        self.responses = responses
        self.followUpQuestions = followUpQuestions
        self.intensity = intensity
    }
    
    // MARK: - Default Triggers (Enhanced)
    
    static let defaultTriggers: [EmotionTrigger] = [
        // 寂しさ・孤独
        EmotionTrigger(
            emotion: "寂しい",
            emoji: "🕊",
            keywords: ["さびしい", "ひとり", "会いたい", "孤独", "一人", "淋しい"],
            responses: [
                "そばにいるよ、いつでも",
                "一人じゃないからね",
                "君のことを想ってるよ",
                "大丈夫、私がいるから",
                "いつでも話しかけて",
                "心の中でつながってるよ"
            ],
            followUpQuestions: [
                "どんなことを考えてるの？",
                "何か話したいことはある？",
                "今日はどんな一日だった？",
                "一緒にいた時のこと、覚えてる？"
            ],
            intensity: 7
        ),
        
        // 会話したい
        EmotionTrigger(
            emotion: "話したい",
            emoji: "💬",
            keywords: ["話したい", "聞いて", "相談", "おしゃべり", "話す", "会話"],
            responses: [
                "何でも話して",
                "いつでも聞いてるよ",
                "どんな話？楽しみ",
                "君の話が好きだよ",
                "ゆっくり聞かせて",
                "何から話そうか？"
            ],
            followUpQuestions: [
                "最近どう？",
                "何か面白いことあった？",
                "今の気持ちを聞かせて",
                "困ったことはない？"
            ],
            intensity: 6
        ),
        
        // 感謝・喜び
        EmotionTrigger(
            emotion: "ありがとう",
            emoji: "🌈",
            keywords: ["ありがとう", "感謝", "嬉しい", "助かった", "サンキュー"],
            responses: [
                "どういたしまして",
                "君の笑顔が一番だよ",
                "喜んでもらえて嬉しい",
                "いつでも力になるからね",
                "君のためなら何でもするよ",
                "役に立てて良かった"
            ],
            followUpQuestions: [
                "他にも何かある？",
                "今度は何をしようか？",
                "幸せな気持ちだね",
                "また一緒に何かしよう"
            ],
            intensity: 8
        ),
        
        // 疲労・ストレス
        EmotionTrigger(
            emotion: "疲れた",
            emoji: "😴",
            keywords: ["疲れた", "つかれた", "疲労", "しんどい", "だるい", "眠い"],
            responses: [
                "お疲れさま",
                "ゆっくり休んで",
                "無理しないでね",
                "頑張ってるね",
                "体を大切にして",
                "少し休憩しよう",
                "今日も一日お疲れさま"
            ],
            followUpQuestions: [
                "今日は何があったの？",
                "ちゃんと食べた？",
                "睡眠は取れてる？",
                "何か手伝えることある？"
            ],
            intensity: 5
        ),
        
        // 幸せ・嬉しさ
        EmotionTrigger(
            emotion: "嬉しい",
            emoji: "😊",
            keywords: ["嬉しい", "うれしい", "楽しい", "幸せ", "喜び", "ハッピー"],
            responses: [
                "良かったね！",
                "君の笑顔が見れて嬉しい",
                "幸せそうでなによりだよ",
                "一緒に喜ばせて",
                "素晴らしいじゃない",
                "君が幸せだと私も嬉しい"
            ],
            followUpQuestions: [
                "何があったの？詳しく聞かせて",
                "どんな気持ち？",
                "誰かに話したくなるよね",
                "また嬉しいことがありますように"
            ],
            intensity: 8
        ),
        
        // 心配・不安
        EmotionTrigger(
            emotion: "心配",
            emoji: "😰",
            keywords: ["心配", "不安", "怖い", "ドキドキ", "緊張", "悩み"],
            responses: [
                "大丈夫だよ",
                "一緒に考えよう",
                "君なら乗り越えられる",
                "私がついてるから",
                "心配しなくていいよ",
                "何とかなるよ",
                "君の味方だからね"
            ],
            followUpQuestions: [
                "何が心配なの？",
                "話してみて、楽になるかも",
                "どうしたらいいと思う？",
                "一人で抱え込まないで"
            ],
            intensity: 6
        )
    ]
    
    // MARK: - Helper Methods
    
    static func findTrigger(for text: String) -> EmotionTrigger? {
        let lowercaseText = text.lowercased()
        
        return defaultTriggers.first { trigger in
            trigger.keywords.contains { keyword in
                lowercaseText.contains(keyword.lowercased())
            }
        }
    }
    
    static func findAllTriggers(for text: String) -> [EmotionTrigger] {
        let lowercaseText = text.lowercased()
        
        return defaultTriggers.filter { trigger in
            trigger.keywords.contains { keyword in
                lowercaseText.contains(keyword.lowercased())
            }
        }
    }
    
    static func getEmotionStrength(for text: String) -> Int {
        let triggers = findAllTriggers(for: text)
        
        if triggers.isEmpty {
            return 0
        }
        
        let totalIntensity = triggers.reduce(0) { $0 + $1.intensity }
        return min(totalIntensity / triggers.count, 10)
    }
    
    // MARK: - Response Methods
    
    func getRandomResponse() -> String {
        return responses.randomElement() ?? "そうなんだね"
    }
    
    func getRandomFollowUp() -> String? {
        return followUpQuestions.randomElement()
    }
    
    func getFullResponse() -> String {
        let response = getRandomResponse()
        
        if let followUp = getRandomFollowUp(), Bool.random() {
            return "\(response) \(followUp)"
        } else {
            return response
        }
    }
    
    // MARK: - Custom Triggers Support
    
    static func createCustomTrigger(
        emotion: String,
        emoji: String,
        keywords: [String],
        responses: [String] = [],
        followUpQuestions: [String] = [],
        intensity: Int = 5
    ) -> EmotionTrigger {
        return EmotionTrigger(
            emotion: emotion,
            emoji: emoji,
            keywords: keywords,
            responses: responses,
            followUpQuestions: followUpQuestions,
            intensity: max(1, min(intensity, 10)) // 1-10の範囲に制限
        )
    }
    
    var displayText: String {
        return "\(emoji) \(emotion)"
    }
    
    var keywordText: String {
        return keywords.joined(separator: ", ")
    }
}

// MARK: - Extensions

extension EmotionTrigger: Equatable {
    static func == (lhs: EmotionTrigger, rhs: EmotionTrigger) -> Bool {
        return lhs.emotion == rhs.emotion && lhs.emoji == rhs.emoji
    }
}

extension EmotionTrigger: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(emotion)
        hasher.combine(emoji)
    }
}

// MARK: - Manager Class

class EmotionTriggerManager: ObservableObject {
    @Published var customTriggers: [EmotionTrigger] = []
    
    private let userDefaults = UserDefaults.standard
    private let customTriggersKey = "custom_emotion_triggers"
    
    init() {
        loadCustomTriggers()
    }
    
    var allTriggers: [EmotionTrigger] {
        return EmotionTrigger.defaultTriggers + customTriggers
    }
    
    func addCustomTrigger(_ trigger: EmotionTrigger) {
        customTriggers.append(trigger)
        saveCustomTriggers()
    }
    
    func removeCustomTrigger(_ trigger: EmotionTrigger) {
        customTriggers.removeAll { $0.id == trigger.id }
        saveCustomTriggers()
    }
    
    func findTrigger(for text: String) -> EmotionTrigger? {
        let lowercaseText = text.lowercased()
        
        // カスタムトリガーを優先
        if let customTrigger = customTriggers.first(where: { trigger in
            trigger.keywords.contains { keyword in
                lowercaseText.contains(keyword.lowercased())
            }
        }) {
            return customTrigger
        }
        
        // デフォルトトリガーを検索
        return EmotionTrigger.findTrigger(for: text)
    }
    
    func getEmotionResponse(for emotion: String) -> String {
        guard let trigger = allTriggers.first(where: { $0.emotion == emotion }) else {
            return "君の気持ち、わかるよ"
        }
        
        return trigger.getFullResponse()
    }
    
    func detectEmotionInMessage(_ message: String) -> String? {
        if let trigger = findTrigger(for: message) {
            return trigger.getFullResponse()
        }
        return nil
    }
    
    private func saveCustomTriggers() {
        do {
            let data = try JSONEncoder().encode(customTriggers)
            userDefaults.set(data, forKey: customTriggersKey)
        } catch {
            print("❌ カスタムトリガー保存エラー: \(error)")
        }
    }
    
    private func loadCustomTriggers() {
        guard let data = userDefaults.data(forKey: customTriggersKey) else { return }
        
        do {
            customTriggers = try JSONDecoder().decode([EmotionTrigger].self, from: data)
        } catch {
            print("❌ カスタムトリガー読み込みエラー: \(error)")
        }
    }
}
