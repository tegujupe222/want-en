import Foundation

class EmotionResponder {
    // ✅ 統合版EmotionTriggerManagerを使用
    private let emotionTriggerManager = EmotionTriggerManager.shared
    
    // ✅ 後方互換性のため、既存のプロパティも保持
    private var emotionTriggers: [EmotionTrigger] {
        return emotionTriggerManager.allTriggers
    }
    
    // ✅ シングルトンパターンに変更
    static let shared = EmotionResponder()
    
    private init() {
        print("🎭 EmotionResponder初期化完了")
    }
    
    // MARK: - Public Methods
    
    func getEmotionResponse(for emotion: String) -> String {
        return emotionTriggerManager.getEmotionResponse(for: emotion)
    }
    
    func detectEmotionInMessage(_ message: String) -> String? {
        return emotionTriggerManager.detectEmotionInMessage(message)
    }
    
    func getAllEmotions() -> [EmotionTrigger] {
        return emotionTriggerManager.allTriggers
    }
    
    func getEmotionByEmoji(_ emoji: String) -> EmotionTrigger? {
        return emotionTriggers.first { $0.emoji == emoji }
    }
    
    // ✅ カスタム感情の追加（統合版に対応）
    func addCustomEmotion(
        emotion: String,
        emoji: String,
        keywords: [String],
        responses: [String],
        followUpQuestions: [String] = [],
        intensity: Int = 5
    ) {
        let newTrigger = EmotionTrigger.createCustomTrigger(
            emotion: emotion,
            emoji: emoji,
            keywords: keywords,
            responses: responses,
            followUpQuestions: followUpQuestions,
            intensity: intensity
        )
        
        emotionTriggerManager.addCustomTrigger(newTrigger)
        print("🆕 新しい感情トリガーを追加: \(newTrigger.emotion) \(newTrigger.emoji)")
    }
    
    func getEmotionalContext(from messages: [ChatMessage]) -> String? {
        // 最近のメッセージから感情的な文脈を分析
        let recentMessages = Array(messages.suffix(5))
        
        for message in recentMessages.reversed() {
            if let emotionResponse = detectEmotionInMessage(message.content) {
                return emotionResponse
            }
        }
        
        return nil
    }
    
    // ✅ 感情分析の詳細情報を取得
    func analyzeEmotionalState(from messages: [ChatMessage]) -> EmotionalAnalysis {
        let recentMessages = Array(messages.suffix(10))
        
        var detectedEmotions: [String: Int] = [:]
        var overallIntensity = 0
        var contextualHints: [String] = []
        
        for message in recentMessages {
            let triggers = EmotionTrigger.findAllTriggers(for: message.content)
            
            for trigger in triggers {
                detectedEmotions[trigger.emotion, default: 0] += 1
                overallIntensity += trigger.intensity
                
                // コンテキストヒントを追加
                if let randomHint = trigger.followUpQuestions.randomElement() {
                    contextualHints.append(randomHint)
                }
            }
        }
        
        let dominantEmotion = detectedEmotions.max(by: { $0.value < $1.value })?.key
        let averageIntensity = detectedEmotions.isEmpty ? 0 : overallIntensity / detectedEmotions.values.reduce(0, +)
        
        return EmotionalAnalysis(
            dominantEmotion: dominantEmotion,
            emotionCounts: detectedEmotions,
            averageIntensity: averageIntensity,
            contextualHints: Array(contextualHints.prefix(3))
        )
    }
    
    // ✅ パーソナライズされた応答生成
    func generatePersonalizedResponse(
        for message: String,
        persona: UserPersona,
        emotionalContext: EmotionalAnalysis? = nil
    ) -> String {
        // 1. 感情検出
        if let trigger = emotionTriggerManager.findTrigger(for: message) {
            var response = trigger.getRandomResponse()
            
            // 2. ペルソナの特徴を反映
            response = personalizeResponse(response, for: persona)
            
            // 3. 感情的コンテキストを考慮
            if let context = emotionalContext,
               let hint = context.contextualHints.randomElement(),
               Bool.random() {
                response += " " + hint
            }
            
            return response
        }
        
        // 4. デフォルト応答（ペルソナベース）
        return generateDefaultResponse(for: persona)
    }
    
    // ✅ 時間帯を考慮した応答生成
    func generateTimeAwareResponse(for emotion: String) -> String {
        let baseResponse = getEmotionResponse(for: emotion)
        let hour = Calendar.current.component(.hour, from: Date())
        
        var timeModifier = ""
        
        switch hour {
        case 5..<12:
            timeModifier = "朝から"
        case 12..<17:
            timeModifier = "お昼に"
        case 17..<21:
            timeModifier = "夕方から"
        case 21...23, 0..<5:
            timeModifier = "夜遅くに"
        default:
            break
        }
        
        if !timeModifier.isEmpty && Bool.random() {
            return "\(timeModifier)\(baseResponse)"
        }
        
        return baseResponse
    }
    
    // MARK: - Private Methods
    
    private func personalizeResponse(_ response: String, for persona: UserPersona) -> String {
        // ペルソナの口癖を時々混ぜる
        if let catchphrase = persona.catchphrases.randomElement(),
           Bool.random() && response.count < 50 {
            return "\(catchphrase) \(response)"
        }
        
        // ペルソナの関係性に応じた調整
        switch persona.relationship.lowercased() {
        case let r where r.contains("家族") || r.contains("母") || r.contains("父"):
            return response.replacingOccurrences(of: "君", with: "あなた")
        case let r where r.contains("友"):
            return response
        case let r where r.contains("恋人"):
            return response + "♪"
        default:
            return response
        }
    }
    
    private func generateDefaultResponse(for persona: UserPersona) -> String {
        let defaultResponses = [
            "そうなんだね",
            "聞いてるよ",
            "どう思う？",
            "なるほど",
            "そうだったんだ"
        ]
        
        let baseResponse = defaultResponses.randomElement() ?? "そうなんだね"
        return personalizeResponse(baseResponse, for: persona)
    }
}

// MARK: - Supporting Structures

struct EmotionalAnalysis {
    let dominantEmotion: String?
    let emotionCounts: [String: Int]
    let averageIntensity: Int
    let contextualHints: [String]
    
    var isPositive: Bool {
        let positiveEmotions = ["嬉しい", "ありがとう", "楽しい", "幸せ"]
        return dominantEmotion.map { positiveEmotions.contains($0) } ?? false
    }
    
    var isNegative: Bool {
        let negativeEmotions = ["寂しい", "疲れた", "心配", "悲しい"]
        return dominantEmotion.map { negativeEmotions.contains($0) } ?? false
    }
    
    var emotionalIntensityLevel: EmotionalIntensity {
        switch averageIntensity {
        case 0...3:
            return .low
        case 4...6:
            return .medium
        case 7...10:
            return .high
        default:
            return .medium
        }
    }
}

enum EmotionalIntensity {
    case low, medium, high
    
    var description: String {
        switch self {
        case .low:
            return "穏やか"
        case .medium:
            return "普通"
        case .high:
            return "強い"
        }
    }
}

// MARK: - Extensions

extension EmotionTriggerManager {
    static let shared = EmotionTriggerManager()
}

// MARK: - Legacy Support

extension EmotionResponder {
    // ✅ 旧式の addCustomEmotion メソッドとの互換性
    @available(*, deprecated, message: "Use the new addCustomEmotion method with responses and followUpQuestions")
    func addCustomEmotion(emotion: String,
                         emoji: String,
                         keywords: [String]) {
        addCustomEmotion(
            emotion: emotion,
            emoji: emoji,
            keywords: keywords,
            responses: ["そうなんだね"],
            followUpQuestions: ["どう思う？"],
            intensity: 5
        )
    }
}
