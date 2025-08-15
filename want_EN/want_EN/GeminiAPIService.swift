import Foundation

class GeminiAPIService {
    // Vercel proxy configuration
    private let vercelBaseURL: String
    
    init(vercelBaseURL: String) {
        self.vercelBaseURL = vercelBaseURL
        print("🤖 GeminiAPIService initialized - Vercel Proxy Mode, Base URL: \(vercelBaseURL)")
    }
    
    // Vercel proxy request/response structures
    struct VercelRequest: Codable {
        let prompt: String
        let persona: UserPersona
        let conversationHistory: [ChatMessage]
    }
    
    struct VercelResponse: Codable {
        let success: Bool
        let response: String
        let model: String
    }
    
    func generateResponse(
        persona: UserPersona,
        conversationHistory: [ChatMessage],
        userMessage: String,
        emotionContext: String? = nil
    ) async throws -> String {
        
        print("🤖 Gemini 2.0 Flash Lite API call started via Vercel proxy")
        
        // Build the prompt with persona context
        let prompt = buildPrompt(persona: persona, conversationHistory: conversationHistory, userMessage: userMessage, emotionContext: emotionContext)
        
        // Create Vercel proxy request
        let vercelRequest = VercelRequest(
            prompt: prompt,
            persona: persona,
            conversationHistory: conversationHistory
        )
        
        // Encode request
        let jsonData = try JSONEncoder().encode(vercelRequest)
        
        // Create URL request
        guard let url = URL(string: "\(vercelBaseURL)/api/gemini-proxy") else {
            throw AIChatError.invalidURL
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = jsonData
        
        print("📡 Sending request to Vercel proxy")
        
        // Make the request
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        
        // Check HTTP response
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIChatError.networkError
        }
        
        print("📡 HTTP Response: \(httpResponse.statusCode)")
        
        // Handle different status codes
        switch httpResponse.statusCode {
        case 200:
            // Success - parse response
            let vercelResponse = try JSONDecoder().decode(VercelResponse.self, from: data)
            
            if vercelResponse.success {
                print("✅ Response received successfully")
                return vercelResponse.response
            } else {
                throw AIChatError.apiError("API returned success=false")
            }
            
        case 400:
            throw AIChatError.apiError("Bad request - check your input")
            
        case 401:
            throw AIChatError.apiError("Unauthorized - check API key configuration")
            
        case 429:
            throw AIChatError.apiError("Rate limit exceeded - please try again later")
            
        case 500:
            throw AIChatError.apiError("Server error - please try again later")
            
        default:
            throw AIChatError.apiError("Unexpected status code: \(httpResponse.statusCode)")
        }
    }
    
    // MARK: - Private Methods
    
    private func buildPrompt(
        persona: UserPersona,
        conversationHistory: [ChatMessage],
        userMessage: String,
        emotionContext: String?
    ) -> String {
        var prompt = ""
        
        // Add persona context
        prompt += "Persona Information:\n"
        prompt += "Name: \(persona.name)\n"
        prompt += "Relationship: \(persona.relationship)\n"
        prompt += "Personality: \(persona.personality)\n"
        prompt += "Speech Style: \(persona.speechStyle)\n"
        prompt += "\nPlease respond as this persona would, maintaining their personality and speech style.\n\n"
        
        // Add conversation history (last 10 messages for context)
        if !conversationHistory.isEmpty {
            prompt += "Previous conversation:\n"
            let recentHistory = Array(conversationHistory.suffix(10))
            for message in recentHistory {
                let role = message.isFromUser ? "User" : "Assistant"
                prompt += "\(role): \(message.content)\n"
            }
            prompt += "\n"
        }
        
        // Add emotion context if available
        if let emotionContext = emotionContext, !emotionContext.isEmpty {
            prompt += "Emotion Context: \(emotionContext)\n\n"
        }
        
        // Add current user message
        prompt += "Current message: \(userMessage)"
        
        return prompt
    }
}
