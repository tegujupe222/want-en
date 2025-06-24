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
        // デフォルト設定を読み込み
        if let data = UserDefaults.standard.data(forKey: configKey),
           let config = try? JSONDecoder().decode(AIConfig.self, from: data) {
            self.currentConfig = config
        } else {
            // デフォルト設定
            self.currentConfig = AIConfig(
                isAIEnabled: true,
                provider: .gemini,
                cloudFunctionURL: "https://asia-northeast1-gen-lang-client-0344989001.cloudfunctions.net/geminiProxy"
            )
        }
        
        print("🤖 AIConfigManager初期化完了")
    }
    
    // MARK: - Public Methods
    
    func enableAI() {
        currentConfig.isAIEnabled = true
        print("✅ AI機能を有効化しました")
    }
    
    func disableAI() {
        currentConfig.isAIEnabled = false
        print("❌ AI機能を無効化しました")
    }
    
    func updateCloudFunctionURL(_ url: String) {
        currentConfig.cloudFunctionURL = url
        print("🔗 Cloud Function URLを更新: \(url)")
    }
    
    func resetToDefaults() {
        currentConfig = AIConfig(
            isAIEnabled: true,
            provider: .gemini,
            cloudFunctionURL: "https://asia-northeast1-gen-lang-client-0344989001.cloudfunctions.net/geminiProxy"
        )
        print("🔄 設定をデフォルトにリセットしました")
    }
    
    // MARK: - Private Methods
    
    private func saveConfig() {
        if let data = try? JSONEncoder().encode(currentConfig) {
            UserDefaults.standard.set(data, forKey: configKey)
            print("💾 AI設定を保存しました")
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
        
        var displayName: String {
            switch self {
            case .gemini:
                return "Google Gemini"
            }
        }
    }
}
