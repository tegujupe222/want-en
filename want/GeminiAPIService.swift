import Foundation

class GeminiAPIService {
    // Cloud Function URL（動的に設定可能）
    private let cloudFunctionURL: String
    
    init(cloudFunctionURL: String) {
        self.cloudFunctionURL = cloudFunctionURL
        print("🤖 GeminiAPIService初期化完了 - URL: \(cloudFunctionURL)")
    }
    
    // リクエスト用の構造体
    struct GeminiRequest: Codable {
        let persona: UserPersona
        let conversationHistory: [ChatMessage]
        let userMessage: String
        let emotionContext: String?
    }
    
    struct GeminiResponse: Codable {
        let response: String
        let error: String?
    }
    
    func generateResponse(
        persona: UserPersona,
        conversationHistory: [ChatMessage],
        userMessage: String,
        emotionContext: String? = nil
    ) async throws -> String {
        
        print("🤖 Gemini API呼び出し開始")
        
        // リクエストデータを作成
        let request = GeminiRequest(
            persona: persona,
            conversationHistory: conversationHistory,
            userMessage: userMessage,
            emotionContext: emotionContext
        )
        
        // JSONエンコード
        let jsonData = try JSONEncoder().encode(request)
        
        // URLリクエストを作成
        guard let url = URL(string: cloudFunctionURL) else {
            throw AIChatError.invalidURL
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = jsonData
        
        // ネットワークリクエスト実行
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        
        // レスポンスチェック
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIChatError.networkError
        }
        
        guard httpResponse.statusCode == 200 else {
            print("❌ HTTP Error: \(httpResponse.statusCode)")
            throw AIChatError.serverError(httpResponse.statusCode)
        }
        
        // レスポンスデコード
        let geminiResponse = try JSONDecoder().decode(GeminiResponse.self, from: data)
        
        if let error = geminiResponse.error {
            throw AIChatError.apiError(NSError(domain: "GeminiAPI", code: -1, userInfo: [NSLocalizedDescriptionKey: error]))
        }
        
        print("✅ Gemini API呼び出し成功")
        return geminiResponse.response
    }
    
    func testConnection() async throws -> Bool {
        print("🔍 Gemini API接続テスト開始")
        
        // テスト用の簡単なリクエスト
        let testPersona = UserPersona(
            name: "Test",
            relationship: "テスト用",
            personality: ["テスト用"],
            speechStyle: "テスト用",
            catchphrases: ["テスト"],
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
            
            print("✅ 接続テスト成功: \(response)")
            return true
            
        } catch {
            print("❌ 接続テスト失敗: \(error)")
            throw error
        }
    }
}

// MARK: - Error Types

enum GeminiAPIError: LocalizedError {
    case invalidResponse
    case badRequest
    case unauthorized
    case forbidden
    case endpointNotFound  // ✅ 追加
    case rateLimitExceeded
    case serverError
    case unknownError(Int)
    case invalidResponseFormat
    case jsonParsingError(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "無効な応答です"
        case .badRequest:
            return "無効なリクエストです"
        case .unauthorized:
            return "APIキーが無効です。設定を確認してください。"
        case .forbidden:
            return "APIアクセスが拒否されました"
        case .endpointNotFound:
            return "APIエンドポイントが見つかりません。URLを確認してください。"
        case .rateLimitExceeded:
            return "API利用制限に達しました。しばらく待ってから再試行してください。"
        case .serverError:
            return "サーバーエラーが発生しました"
        case .unknownError(let code):
            return "不明なエラーが発生しました (コード: \(code))"
        case .invalidResponseFormat:
            return "APIの応答形式が不正です"
        case .jsonParsingError(let error):
            return "JSON解析エラー: \(error.localizedDescription)"
        }
    }
}
