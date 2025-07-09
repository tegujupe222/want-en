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
        print("🔗 Vercel Server URL: \(vercelServerURL)")
        print("👤 Persona: \(persona.name) (\(persona.relationship))")
        print("💬 User message: \(userMessage)")
        print("📚 Conversation history count: \(conversationHistory.count)")
        
        // Create request data
        let request = OpenAIRequest(
            persona: persona,
            conversationHistory: conversationHistory,
            userMessage: userMessage,
            emotionContext: emotionContext
        )
        
        // JSON encode
        let jsonData = try JSONEncoder().encode(request)
        print("📦 Request data size: \(jsonData.count) bytes")
        
        // Create URL request
        guard let url = URL(string: vercelServerURL) else {
            print("❌ Invalid URL: \(vercelServerURL)")
            throw AIChatError.invalidURL
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = jsonData
        
        print("📡 Sending POST request to: \(url)")
        
        // Execute network request
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        
        print("📥 Received response data size: \(data.count) bytes")
        
        // Check response
        guard let httpResponse = response as? HTTPURLResponse else {
            print("❌ Invalid response type")
            throw AIChatError.networkError
        }
        
        print("📊 HTTP Status Code: \(httpResponse.statusCode)")
        print("📋 Response Headers: \(httpResponse.allHeaderFields)")
        
        guard httpResponse.statusCode == 200 else {
            let responseText = String(data: data, encoding: .utf8) ?? "Unable to decode response"
            print("❌ HTTP Error: \(httpResponse.statusCode)")
            print("❌ Error Response: \(responseText)")
            throw AIChatError.serverError(httpResponse.statusCode)
        }
        
        // Decode response
        let responseText = String(data: data, encoding: .utf8) ?? "Unable to decode response"
        print("📄 Raw response: \(responseText)")
        
        let openAIResponse = try JSONDecoder().decode(OpenAIResponse.self, from: data)
        
        if let error = openAIResponse.error {
            print("❌ API Error: \(error)")
            throw AIChatError.apiError(NSError(domain: "OpenAIAPI", code: -1, userInfo: [NSLocalizedDescriptionKey: error]))
        }
        
        print("✅ OpenAI API call successful")
        print("💬 Response: \(openAIResponse.response.prefix(100))...")
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
// Using AIChatError from AIChatService.swift for consistency 