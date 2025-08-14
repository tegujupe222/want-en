import Foundation

class AIChatService {
    
    init() {
        print("🤖 AIChatService initialization completed")
    }
    
    func generateResponse(
        persona: UserPersona,
        conversationHistory: [ChatMessage],
        userMessage: String,
        emotionContext: String? = nil
    ) async throws -> String {
        
        let config = AIConfigManager.shared.currentConfig
        
        guard config.isAIEnabled else {
            throw AIChatError.aiNotEnabled
        }
        
        // Check subscription status
        let subscriptionManager = await SubscriptionManager.shared
        guard await subscriptionManager.canUseAI() else {
            throw AIChatError.subscriptionRequired
        }
        
        // Check if Vercel base URL is configured
        guard !config.vercelBaseURL.isEmpty else {
            throw AIChatError.vercelURLNotSet
        }
        
        return try await generateGeminiResponse(
            persona: persona,
            conversationHistory: conversationHistory,
            userMessage: userMessage,
            emotionContext: emotionContext,
            vercelBaseURL: config.vercelBaseURL
        )
    }
    
    // MARK: - Private Methods
    
    private func generateGeminiResponse(
        persona: UserPersona,
        conversationHistory: [ChatMessage],
        userMessage: String,
        emotionContext: String?,
        vercelBaseURL: String
    ) async throws -> String {
        
        let geminiService = GeminiAPIService(vercelBaseURL: vercelBaseURL)
        
        return try await geminiService.generateResponse(
            persona: persona,
            conversationHistory: conversationHistory,
            userMessage: userMessage,
            emotionContext: emotionContext
        )
    }
    
    // MARK: - Configuration Updates
    
    func updateConfiguration() {
        print("🔄 AI configuration updated")
    }
    
    func testConnection() async throws -> Bool {
        let config = AIConfigManager.shared.currentConfig
        
        guard config.isAIEnabled else {
            throw AIChatError.aiNotEnabled
        }
        
        // Check subscription status
        let subscriptionManager = await SubscriptionManager.shared
        guard await subscriptionManager.canUseAI() else {
            throw AIChatError.subscriptionRequired
        }
        
        guard !config.vercelBaseURL.isEmpty else {
            throw AIChatError.vercelURLNotSet
        }
        
        let geminiService = GeminiAPIService(vercelBaseURL: config.vercelBaseURL)
        
        // Create a test persona and message
        let testPersona = UserPersona(
            name: "Test",
            relationship: "Test Assistant",
            personality: ["Friendly", "Helpful"],
            speechStyle: "Polite and natural",
            catchphrases: ["Hello!", "How can I help?"],
            favoriteTopics: ["Technology", "Science"]
        )
        
        let testMessage = "Hello, how are you today?"
        
        do {
            let response = try await geminiService.generateResponse(
                persona: testPersona,
                conversationHistory: [],
                userMessage: testMessage,
                emotionContext: nil
            )
            
            print("✅ Connection test successful: \(response)")
            return true
            
        } catch {
            print("❌ Connection test failed: \(error)")
            throw error
        }
    }
}

// MARK: - Error Types

enum AIChatError: LocalizedError {
    case aiNotEnabled
    case vercelURLNotSet
    case apiError(String)
    case networkError
    case rateLimitExceeded
    case invalidResponse
    case subscriptionRequired
    case invalidURL
    case serverError(Int)
    
    var errorDescription: String? {
        switch self {
        case .aiNotEnabled:
            return "AI features are not enabled"
        case .vercelURLNotSet:
            return "Vercel base URL is not configured"
        case .apiError(let message):
            return "API error: \(message)"
        case .networkError:
            return "Network error occurred"
        case .rateLimitExceeded:
            return "API rate limit exceeded"
        case .invalidResponse:
            return "Invalid response received"
        case .subscriptionRequired:
            return "Subscription required to use AI features"
        case .invalidURL:
            return "Invalid URL"
        case .serverError(let code):
            return "Server error occurred (status code: \(code))"
        }
    }
}
