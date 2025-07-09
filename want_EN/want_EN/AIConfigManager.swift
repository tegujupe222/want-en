import Foundation

class AIConfigManager: ObservableObject {
    static let shared = AIConfigManager()
    
    @Published var currentConfig: AIConfig {
        didSet {
            saveConfig()
        }
    }
    
    private let configKey = "ai_config"
    
    private init() {
        // Load default settings
        if let data = UserDefaults.standard.data(forKey: configKey),
           let config = try? JSONDecoder().decode(AIConfig.self, from: data) {
            self.currentConfig = config
        } else {
            // Default settings - now using OpenAI
            self.currentConfig = AIConfig(
                isAIEnabled: true,
                provider: .openai,
                cloudFunctionURL: "https://your-vercel-app.vercel.app/api/chat"
            )
        }
        
        print("🤖 AIConfigManager initialization completed")
        
        // Update AI features based on trial status (called asynchronously)
        Task { await self.updateAIStatusBasedOnTrial() }
    }
    
    // MARK: - Public Methods
    
    func enableAI() {
        currentConfig.isAIEnabled = true
        print("✅ AI features enabled")
    }
    
    func disableAI() {
        currentConfig.isAIEnabled = false
        print("❌ AI features disabled")
    }
    
    func updateCloudFunctionURL(_ url: String) {
        currentConfig.cloudFunctionURL = url
        print("🔗 Cloud Function URL updated: \(url)")
    }
    
    func resetToDefaults() {
        currentConfig = AIConfig(
            isAIEnabled: true,
            provider: .openai,
            cloudFunctionURL: "https://your-vercel-app.vercel.app/api/chat"
        )
        print("🔄 Settings reset to defaults")
    }
    
    /// Update AI features based on trial status
    @MainActor
    func updateAIStatusBasedOnTrial() {
        let subscriptionManager = SubscriptionManager.shared
        
        // Enable AI during trial period or with active subscription
        if subscriptionManager.subscriptionStatus == .trial || 
           subscriptionManager.subscriptionStatus == .active {
            if !currentConfig.isAIEnabled {
                enableAI()
            }
        } else {
            // Disable AI after trial ends or without subscription
            if currentConfig.isAIEnabled {
                disableAI()
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func saveConfig() {
        if let data = try? JSONEncoder().encode(currentConfig) {
            UserDefaults.standard.set(data, forKey: configKey)
            print("💾 AI settings saved")
        }
    }
}

// MARK: - Data Models

struct AIConfig: Codable {
    var isAIEnabled: Bool
    var provider: AIProvider
    var cloudFunctionURL: String
    
    enum AIProvider: String, CaseIterable, Codable {
        case gemini = "gemini"
        case openai = "openai"
        
        var displayName: String {
            switch self {
            case .gemini:
                return "Google Gemini"
            case .openai:
                return "OpenAI GPT"
            }
        }
    }
}
