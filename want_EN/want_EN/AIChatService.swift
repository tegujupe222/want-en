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
        
        return try await generateGeminiResponse(
            persona: persona,
            conversationHistory: conversationHistory,
            userMessage: userMessage,
            emotionContext: emotionContext,
            apiKey: config.geminiAPIKey,
            useVercelProxy: config.useVercelProxy,
            vercelBaseURL: config.vercelBaseURL
        )
    }
    
    // MARK: - Private Methods
    
    private func generateGeminiResponse(
        persona: UserPersona,
        conversationHistory: [ChatMessage],
        userMessage: String,
        emotionContext: String?,
        apiKey: String,
        useVercelProxy: Bool,
        vercelBaseURL: String
    ) async throws -> String {
        
        if useVercelProxy {
            // For Vercel proxy, API key is not needed on client side
            let geminiService = GeminiAPIService(
                apiKey: "",
                useVercelProxy: true,
                vercelBaseURL: vercelBaseURL
            )
            
            return try await geminiService.generateResponse(
                persona: persona,
                conversationHistory: conversationHistory,
                userMessage: userMessage,
                emotionContext: emotionContext
            )
        } else {
            // Direct API mode
            guard !apiKey.isEmpty else {
                throw AIChatError.apiKeyNotSet
            }
            
            let geminiService = GeminiAPIService(
                apiKey: apiKey,
                useVercelProxy: false,
                vercelBaseURL: ""
            )
            
            return try await geminiService.generateResponse(
                persona: persona,
                conversationHistory: conversationHistory,
                userMessage: userMessage,
                emotionContext: emotionContext
            )
        }
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
        
        guard !config.geminiAPIKey.isEmpty else {
            throw AIChatError.apiKeyNotSet
        }
        
        let geminiService = GeminiAPIService(
            apiKey: config.geminiAPIKey,
            useVercelProxy: config.useVercelProxy,
            vercelBaseURL: config.vercelBaseURL
        )
        return try await geminiService.testConnection()
    }
}

// MARK: - Error Types

enum AIChatError: LocalizedError {
    case aiNotEnabled
    case apiKeyNotSet
    case apiError(Error)
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
            return "Gemini API key is not set"
        case .apiError(let error):
            return "API connection test failed: \(error.localizedDescription)"
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
