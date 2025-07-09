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
        
        switch config.provider {
        case .gemini:
            return try await generateGeminiResponse(
                persona: persona,
                conversationHistory: conversationHistory,
                userMessage: userMessage,
                emotionContext: emotionContext,
                cloudFunctionURL: config.cloudFunctionURL
            )
        case .openai:
            return try await generateOpenAIResponse(
                persona: persona,
                conversationHistory: conversationHistory,
                userMessage: userMessage,
                emotionContext: emotionContext,
                vercelServerURL: config.cloudFunctionURL
            )
        }
    }
    
    // MARK: - Private Methods
    
    private func generateGeminiResponse(
        persona: UserPersona,
        conversationHistory: [ChatMessage],
        userMessage: String,
        emotionContext: String?,
        cloudFunctionURL: String
    ) async throws -> String {
        
        // Create GeminiAPIService dynamically (pass URL)
        let geminiService = GeminiAPIService(cloudFunctionURL: cloudFunctionURL)
        
        return try await geminiService.generateResponse(
                persona: persona,
                conversationHistory: conversationHistory,
                userMessage: userMessage,
                emotionContext: emotionContext
            )
    }
    
    private func generateOpenAIResponse(
        persona: UserPersona,
        conversationHistory: [ChatMessage],
        userMessage: String,
        emotionContext: String?,
        vercelServerURL: String
    ) async throws -> String {
        
        // Create OpenAIAPIService dynamically (pass URL)
        let openAIService = OpenAIAPIService(vercelServerURL: vercelServerURL)
        
        return try await openAIService.generateResponse(
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
        
        // Simple test persona and message
        let testPersona = UserPersona(
            name: "Test",
            relationship: "Assistant",
            personality: ["Friendly"],
            speechStyle: "Polite",
            catchphrases: ["Hello"],
            favoriteTopics: ["Test"]
        )
        
        let testMessage = "Hello"
        
        do {
            let response = try await generateResponse(
                persona: testPersona,
                conversationHistory: [],
                userMessage: testMessage,
                emotionContext: nil
            )
            
            print("✅ AI connection test successful: \(response.prefix(50))...")
            return true
            
        } catch {
            print("❌ AI connection test failed: \(error)")
            throw error
        }
    }
}

// MARK: - Error Types

enum AIChatError: LocalizedError {
    case aiNotEnabled
    case apiKeyNotSet
    case apiError(Error)
    case invalidProvider
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
        case .apiKeyNotSet:
            return "API key is not set"
        case .apiError(let error):
            return "API connection test failed: \(error.localizedDescription)"
        case .invalidProvider:
            return "Invalid AI provider"
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
