import Foundation

class AIChatService {
    
    init() {
        print("🤖 AIChatService初期化完了")
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
        
        // サブスクリプション状態をチェック
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
        
        // GeminiAPIServiceを動的に作成（URLを渡す）
        let geminiService = GeminiAPIService(cloudFunctionURL: cloudFunctionURL)
        
        return try await geminiService.generateResponse(
            persona: persona,
            conversationHistory: conversationHistory,
            userMessage: userMessage,
            emotionContext: emotionContext
        )
    }
    
    // MARK: - Configuration Updates
    
    func updateConfiguration() {
        print("🔄 AI設定を更新しました")
    }
    
    func testConnection() async throws -> Bool {
        let config = AIConfigManager.shared.currentConfig
        
        guard config.isAIEnabled else {
            throw AIChatError.aiNotEnabled
        }
        
        // サブスクリプション状態をチェック
        let subscriptionManager = await SubscriptionManager.shared
        guard await subscriptionManager.canUseAI() else {
            throw AIChatError.subscriptionRequired
        }
        
        // テスト用の簡単なペルソナとメッセージ
        let testPersona = UserPersona(
            name: "テスト",
            relationship: "アシスタント",
            personality: ["親しみやすい"],
            speechStyle: "丁寧",
            catchphrases: ["こんにちは"],
            favoriteTopics: ["テスト"]
        )
        
        let testMessage = "こんにちは"
        
        do {
            let response = try await generateResponse(
                persona: testPersona,
                conversationHistory: [],
                userMessage: testMessage,
                emotionContext: nil
            )
            
            print("✅ AI接続テスト成功: \(response.prefix(50))...")
            return true
            
        } catch {
            print("❌ AI接続テスト失敗: \(error)")
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
            return "AI機能が有効になっていません"
        case .apiKeyNotSet:
            return "APIキーが設定されていません"
        case .apiError(let error):
            return "API接続テスト失敗: \(error.localizedDescription)"
        case .invalidProvider:
            return "無効なAIプロバイダーです"
        case .networkError:
            return "ネットワークエラーが発生しました"
        case .rateLimitExceeded:
            return "APIの利用制限に達しました"
        case .invalidResponse:
            return "無効な応答を受信しました"
        case .subscriptionRequired:
            return "AI機能を使用するにはサブスクリプションが必要です"
        case .invalidURL:
            return "無効なURLです"
        case .serverError(let code):
            return "サーバーエラーが発生しました（ステータスコード: \(code)）"
        }
    }
}
