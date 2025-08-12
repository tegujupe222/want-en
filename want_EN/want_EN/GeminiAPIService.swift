import Foundation

class GeminiAPIService {
    // Gemini 2.5 Flash Lite API configuration
    private let apiKey: String
    private let useVercelProxy: Bool
    private let vercelBaseURL: String
    private let directBaseURL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash-exp:generateContent"
    
    init(apiKey: String, useVercelProxy: Bool = false, vercelBaseURL: String = "") {
        self.apiKey = apiKey
        self.useVercelProxy = useVercelProxy
        self.vercelBaseURL = vercelBaseURL
        print("🤖 GeminiAPIService initialized - Mode: \(useVercelProxy ? "Vercel Proxy" : "Direct API"), API Key: \(String(apiKey.prefix(8)))...")
    }
    
    // Request structure for Gemini 2.5 Flash Lite
    struct GeminiRequest: Codable {
        let contents: [Content]
        let generationConfig: GenerationConfig?
        let safetySettings: [SafetySetting]?
    }
    
    struct Content: Codable {
        let parts: [Part]
    }
    
    struct Part: Codable {
        let text: String
    }
    
    struct GenerationConfig: Codable {
        let temperature: Double
        let topK: Int
        let topP: Double
        let maxOutputTokens: Int
        let stopSequences: [String]?
    }
    
    struct SafetySetting: Codable {
        let category: String
        let threshold: String
    }
    
    struct GeminiResponse: Codable {
        let candidates: [Candidate]?
        let promptFeedback: PromptFeedback?
    }
    
    struct Candidate: Codable {
        let content: Content
        let finishReason: String?
        let index: Int?
        let safetyRatings: [SafetyRating]?
    }
    
    struct PromptFeedback: Codable {
        let safetyRatings: [SafetyRating]?
    }
    
    struct SafetyRating: Codable {
        let category: String
        let probability: String
    }
    
    // Vercel proxy request/response structures
    struct VercelRequest: Codable {
        let prompt: String
        let persona: UserPersona
        let conversationHistory: [ChatMessage]
    }
    
    struct VercelResponse: Codable {
        let response: String
        let model: String
        let timestamp: String
    }
    
    func generateResponse(
        persona: UserPersona,
        conversationHistory: [ChatMessage],
        userMessage: String,
        emotionContext: String? = nil
    ) async throws -> String {
        
        print("🤖 Gemini 2.5 Flash Lite API call started")
        
        // Build the prompt with persona context
        let prompt = buildPrompt(persona: persona, conversationHistory: conversationHistory, userMessage: userMessage, emotionContext: emotionContext)
        
        // Create request
        let request = GeminiRequest(
            contents: [Content(parts: [Part(text: prompt)])],
            generationConfig: GenerationConfig(
                temperature: 0.7,
                topK: 40,
                topP: 0.95,
                maxOutputTokens: 1000,
                stopSequences: nil
            ),
            safetySettings: [
                SafetySetting(category: "HARM_CATEGORY_HARASSMENT", threshold: "BLOCK_MEDIUM_AND_ABOVE"),
                SafetySetting(category: "HARM_CATEGORY_HATE_SPEECH", threshold: "BLOCK_MEDIUM_AND_ABOVE"),
                SafetySetting(category: "HARM_CATEGORY_SEXUALLY_EXPLICIT", threshold: "BLOCK_MEDIUM_AND_ABOVE"),
                SafetySetting(category: "HARM_CATEGORY_DANGEROUS_CONTENT", threshold: "BLOCK_MEDIUM_AND_ABOVE")
            ]
        )
        
        // JSON encode
        let jsonData = try JSONEncoder().encode(request)
        
        // Create URL request based on mode
        let url: URL
        var urlRequest: URLRequest
        
        if useVercelProxy {
            // Use Vercel proxy
            guard let vercelURL = URL(string: "\(vercelBaseURL)/api/gemini-proxy") else {
                throw AIChatError.invalidURL
            }
            url = vercelURL
            
            // Create Vercel proxy request
            let vercelRequest = VercelRequest(
                prompt: userMessage,
                persona: persona,
                conversationHistory: conversationHistory
            )
            let vercelJsonData = try JSONEncoder().encode(vercelRequest)
            
            urlRequest = URLRequest(url: url)
            urlRequest.httpMethod = "POST"
            urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
            urlRequest.httpBody = vercelJsonData
            
            print("📡 Sending request to Vercel proxy")
        } else {
            // Use direct API
            guard let directURL = URL(string: "\(directBaseURL)?key=\(apiKey)") else {
                throw AIChatError.invalidURL
            }
            url = directURL
            
            urlRequest = URLRequest(url: url)
            urlRequest.httpMethod = "POST"
            urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
            urlRequest.httpBody = jsonData
            
            print("📡 Sending request to Gemini 2.5 Flash Lite API")
        }
        
        // Execute network request
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        
        // Check response
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIChatError.networkError
        }
        
        guard httpResponse.statusCode == 200 else {
            let responseText = String(data: data, encoding: .utf8) ?? "Unable to decode response"
            print("❌ HTTP Error: \(httpResponse.statusCode)")
            print("❌ Error Response: \(responseText)")
            throw AIChatError.serverError(httpResponse.statusCode)
        }
        
        // Decode response based on mode
        if useVercelProxy {
            let vercelResponse = try JSONDecoder().decode(VercelResponse.self, from: data)
            print("✅ Vercel proxy call successful")
            return vercelResponse.response.trimmingCharacters(in: .whitespacesAndNewlines)
        } else {
            let geminiResponse = try JSONDecoder().decode(GeminiResponse.self, from: data)
            
            guard let candidate = geminiResponse.candidates?.first,
                  let text = candidate.content.parts.first?.text else {
                throw AIChatError.invalidResponse
            }
            
            print("✅ Gemini 2.5 Flash Lite API call successful")
            return text.trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }
    
    private func buildPrompt(persona: UserPersona, conversationHistory: [ChatMessage], userMessage: String, emotionContext: String?) -> String {
        var prompt = """
        You are an AI assistant that responds as a specific persona. Please respond naturally and conversationally.
        
        PERSONA INFORMATION:
        Name: \(persona.name)
        Relationship: \(persona.relationship)
        Personality: \(persona.personality.joined(separator: ", "))
        Speech Style: \(persona.speechStyle)
        Catchphrases: \(persona.catchphrases.joined(separator: ", "))
        Favorite Topics: \(persona.favoriteTopics.joined(separator: ", "))
        
        INSTRUCTIONS:
        - Respond as this persona would naturally speak
        - Keep responses conversational and engaging
        - Use the persona's speech style and personality
        - Incorporate catchphrases naturally when appropriate
        - Show interest in favorite topics
        - Keep responses concise but meaningful
        - Be empathetic and supportive
        """
        
        if let emotionContext = emotionContext {
            prompt += "\n\nEMOTIONAL CONTEXT: \(emotionContext)"
        }
        
        if !conversationHistory.isEmpty {
            prompt += "\n\nCONVERSATION HISTORY:\n"
            for message in conversationHistory.suffix(10) { // Last 10 messages
                let speaker = message.isFromUser ? "User" : persona.name
                prompt += "\(speaker): \(message.content)\n"
            }
        }
        
        prompt += "\n\nUser: \(userMessage)\n\(persona.name):"
        
        return prompt
    }
    
    func testConnection() async throws -> Bool {
        print("🔍 Gemini 2.5 Flash Lite API connection test started")
        
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

enum GeminiAPIError: LocalizedError {
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
            return "Invalid response"
        case .badRequest:
            return "Invalid request"
        case .unauthorized:
            return "API key is invalid. Please check your settings."
        case .forbidden:
            return "API access denied"
        case .endpointNotFound:
            return "API endpoint not found. Please check the URL."
        case .rateLimitExceeded:
            return "API rate limit exceeded. Please try again later."
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
