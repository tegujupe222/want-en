import Foundation

class OpenAIAPIService {
    // Vercel server URL for OpenAI API
    private let vercelServerURL: String
    
    init(vercelServerURL: String) {
        self.vercelServerURL = vercelServerURL
        print("🤖 OpenAIAPIService initialization completed - URL: \(vercelServerURL)")
    }
    
    // Request structure for OpenAI
    struct OpenAIRequest: Codable {
        let persona: UserPersona
        let conversationHistory: [ChatMessage]
        let userMessage: String
        let emotionContext: String?
    }
    
    struct OpenAIResponse: Codable {
        let response: String
        let error: String?
    }
    
    func generateResponse(
        persona: UserPersona,
        conversationHistory: [ChatMessage],
        userMessage: String,
        emotionContext: String? = nil
    ) async throws -> String {
        
        print("🤖 OpenAI API call started")
        
        // Create request data
        let request = OpenAIRequest(
            persona: persona,
            conversationHistory: conversationHistory,
            userMessage: userMessage,
            emotionContext: emotionContext
        )
        
        // JSON encode
        let jsonData = try JSONEncoder().encode(request)
        
        // Create URL request
        guard let url = URL(string: vercelServerURL) else {
            throw AIChatError.invalidURL
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = jsonData
        
        // Execute network request
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        
        // Check response
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIChatError.networkError
        }
        
        guard httpResponse.statusCode == 200 else {
            print("❌ HTTP Error: \(httpResponse.statusCode)")
            throw AIChatError.serverError(httpResponse.statusCode)
        }
        
        // Decode response
        let openAIResponse = try JSONDecoder().decode(OpenAIResponse.self, from: data)
        
        if let error = openAIResponse.error {
            throw AIChatError.apiError(NSError(domain: "OpenAIAPI", code: -1, userInfo: [NSLocalizedDescriptionKey: error]))
        }
        
        print("✅ OpenAI API call successful")
        return openAIResponse.response
    }
    
    func testConnection() async throws -> Bool {
        print("🔍 OpenAI API connection test started")
        
        // Simple test request
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
            let response = try await generateResponse(
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

enum OpenAIAPIError: LocalizedError {
    case invalidResponse
    case badRequest
    case unauthorized
    case forbidden
    case endpointNotFound
    case rateLimitExceeded
    case serverError
    case unknownError(Int)
    case invalidResponseFormat
    case jsonParsingError(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid response received"
        case .badRequest:
            return "Invalid request format"
        case .unauthorized:
            return "API key is invalid. Please check your settings."
        case .forbidden:
            return "API access denied"
        case .endpointNotFound:
            return "API endpoint not found. Please check the URL."
        case .rateLimitExceeded:
            return "API rate limit exceeded. Please wait and try again."
        case .serverError:
            return "Server error occurred"
        case .unknownError(let code):
            return "Unknown error occurred (code: \(code))"
        case .invalidResponseFormat:
            return "Invalid API response format"
        case .jsonParsingError(let error):
            return "JSON parsing error: \(error.localizedDescription)"
        }
    }
} 