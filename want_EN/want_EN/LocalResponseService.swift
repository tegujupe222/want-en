import Foundation

// MARK: - Local Response Service

class LocalResponseService {
    private let emotionResponder = EmotionResponder.shared
    
    init() {
        print("🏠 LocalResponseService初期化完了")
    }
    
    func generateResponse(
        persona: UserPersona,
        conversationHistory: [ChatMessage],
        userMessage: String,
        emotionContext: String?
    ) -> String {
        print("🏠 ローカル応答生成: \(userMessage.prefix(20))...")
        
        // 1. 感情分析
        let emotionalAnalysis = emotionResponder.analyzeEmotionalState(from: conversationHistory)
        
        // 2. パーソナライズされた応答生成
        let personalizedResponse = emotionResponder.generatePersonalizedResponse(
            for: userMessage,
            persona: persona,
            emotionalContext: emotionalAnalysis
        )
        
        // 3. 時間帯を考慮した調整
        if let dominantEmotion = emotionalAnalysis.dominantEmotion {
            let timeAwareResponse = emotionResponder.generateTimeAwareResponse(for: dominantEmotion)
            
            // ランダムに時間帯考慮応答を使用
            if Bool.random() && timeAwareResponse != personalizedResponse {
                return timeAwareResponse
            }
        }
        
        // 4. 会話の流れを考慮した応答調整
        let contextualResponse = adjustResponseForContext(
            baseResponse: personalizedResponse,
            persona: persona,
            recentMessages: Array(conversationHistory.suffix(3))
        )
        
        print("✅ ローカル応答生成完了")
        return contextualResponse
    }
    
    // MARK: - Private Methods
    
    private func adjustResponseForContext(
        baseResponse: String,
        persona: UserPersona,
        recentMessages: [ChatMessage]
    ) -> String {
        var response = baseResponse
        
        // 連続する同じような応答を避ける
        let recentBotMessages = recentMessages.filter { !$0.isFromUser }
        if recentBotMessages.count >= 2 {
            let lastTwoResponses = Array(recentBotMessages.suffix(2)).map { $0.content }
            
            // 同じような応答が続いている場合は変化を加える
            if lastTwoResponses.allSatisfy({ $0.contains("そう") }) {
                response = addVariation(to: response, persona: persona)
            }
        }
        
        // 会話の長さに応じた応答調整
        if recentMessages.count > 20 {
            response = addLongConversationElement(to: response, persona: persona)
        }
        
        return response
    }
    
    private func addVariation(to response: String, persona: UserPersona) -> String {
        let variations = [
            "ところで、",
            "そういえば、",
            "話は変わるけど、",
            "それより、"
        ]
        
        if let variation = variations.randomElement(),
           let topic = persona.favoriteTopics.randomElement() {
            return "\(response) \(variation)\(topic)の話でもしよう？"
        }
        
        return response
    }
    
    private func addLongConversationElement(to response: String, persona: UserPersona) -> String {
        let longConversationElements = [
            "ずっと話してて楽しいな",
            "君といると時間があっという間だね",
            "こうして話せて嬉しいよ",
            "もっと聞かせて"
        ]
        
        if Bool.random(), let element = longConversationElements.randomElement() {
            return "\(response) \(element)。"
        }
        
        return response
    }
}
