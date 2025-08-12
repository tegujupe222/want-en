import Foundation

// MARK: - Local Response Service

class LocalResponseService {
    private let emotionResponder = EmotionResponder.shared
    
    init() {
        print("🏠 LocalResponseService initialization completed")
    }
    
    func generateResponse(
        persona: UserPersona,
        conversationHistory: [ChatMessage],
        userMessage: String,
        emotionContext: String?
    ) -> String {
        print("🏠 Local response generation: \(userMessage.prefix(20))...")
        
        // 1. Emotional analysis
        let emotionalAnalysis = emotionResponder.analyzeEmotionalState(from: conversationHistory)
        
        // 2. Generate personalized response
        let personalizedResponse = emotionResponder.generatePersonalizedResponse(
            for: userMessage,
            persona: persona,
            emotionalContext: emotionalAnalysis
        )
        
        // 3. Time-aware adjustments
        if let dominantEmotion = emotionalAnalysis.dominantEmotion {
            let timeAwareResponse = emotionResponder.generateTimeAwareResponse(for: dominantEmotion)
            
            // Randomly use time-aware response
            if Bool.random() && timeAwareResponse != personalizedResponse {
                return timeAwareResponse
            }
        }
        
        // 4. Context-aware response adjustments
        let contextualResponse = adjustResponseForContext(
            baseResponse: personalizedResponse,
            persona: persona,
            recentMessages: Array(conversationHistory.suffix(3))
        )
        
        print("✅ Local response generation completed")
        return contextualResponse
    }
    
    // MARK: - Private Methods
    
    private func adjustResponseForContext(
        baseResponse: String,
        persona: UserPersona,
        recentMessages: [ChatMessage]
    ) -> String {
        var response = baseResponse
        
        // Avoid repetitive responses
        let recentBotMessages = recentMessages.filter { !$0.isFromUser }
        if recentBotMessages.count >= 2 {
            let lastTwoResponses = Array(recentBotMessages.suffix(2)).map { $0.content }
            
            // Add variation if similar responses continue
            if lastTwoResponses.allSatisfy({ $0.contains("I see") }) {
                response = addVariation(to: response, persona: persona)
            }
        }
        
        // Adjust response based on conversation length
        if recentMessages.count > 20 {
            response = addLongConversationElement(to: response, persona: persona)
        }
        
        return response
    }
    
    private func addVariation(to response: String, persona: UserPersona) -> String {
        let variations = [
            "By the way, ",
            "Speaking of which, ",
            "Changing the subject, ",
            "Anyway, "
        ]
        
        if let variation = variations.randomElement(),
           let topic = persona.favoriteTopics.randomElement() {
            return "\(response) \(variation)shall we talk about \(topic)?"
        }
        
        return response
    }
    
    private func addLongConversationElement(to response: String, persona: UserPersona) -> String {
        let longConversationElements = [
            "It's fun talking with you for so long",
            "Time flies when I'm with you",
            "I'm happy we can talk like this",
            "Tell me more"
        ]
        
        if Bool.random(), let element = longConversationElements.randomElement() {
            return "\(response) \(element)."
        }
        
        return response
    }
}
