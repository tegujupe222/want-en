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
            // Default settings - using Gemini 2.5 Flash Lite only
            self.currentConfig = AIConfig(
                isAIEnabled: true,
                geminiAPIKey: "",
                useVercelProxy: false,
                vercelBaseURL: ""
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
    
    func updateGeminiAPIKey(_ apiKey: String) {
        currentConfig.geminiAPIKey = apiKey
        print("🔑 Gemini API key updated")
    }
    
    func updateVercelSettings(useProxy: Bool, baseURL: String) {
        currentConfig.useVercelProxy = useProxy
        currentConfig.vercelBaseURL = baseURL
        print("🌐 Vercel settings updated: useProxy=\(useProxy), baseURL=\(baseURL)")
    }
    
    func resetToDefaults() {
        currentConfig = AIConfig(
            isAIEnabled: true,
            geminiAPIKey: "",
            useVercelProxy: false,
            vercelBaseURL: ""
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
    var geminiAPIKey: String
    var useVercelProxy: Bool
    var vercelBaseURL: String
    
    init(isAIEnabled: Bool, geminiAPIKey: String, useVercelProxy: Bool = false, vercelBaseURL: String = "") {
        self.isAIEnabled = isAIEnabled
        self.geminiAPIKey = geminiAPIKey
        self.useVercelProxy = useVercelProxy
        self.vercelBaseURL = vercelBaseURL
    }
}
