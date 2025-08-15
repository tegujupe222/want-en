import Foundation
import SwiftUI

@MainActor
class ChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var selectedPersona: UserPersona?
    @Published var currentMessage = ""
    @Published var isTyping = false
    @Published var isLoading = false
    @Published var showSubscriptionAlert = false
    @Published var subscriptionAlertMessage = ""
    
    private let aiChatService = AIChatService()
    private let subscriptionManager = SubscriptionManager.shared
    private let personaManager = PersonaManager.shared
    private let chatRoomManager = ChatRoomManager()
    
    // MARK: - Persistence Keys
    private let messagesKey = "chat_messages"
    private let currentPersonaKey = "current_persona_id"
    
    // Error handling
    @Published var showError = false
    @Published var errorMessage = ""
    
    init() {
        print("🔄 ChatViewModel initialization completed")
        loadPersistedData()
    }
    
    // MARK: - Public Methods
    
    func loadChatHistory(for persona: UserPersona) {
        selectedPersona = persona
        loadMessagesForPersona(persona)
        print("💬 Persona conversation loading: \(persona.name)")
        print("✅ Conversation loading completed: \(messages.count) messages")
    }
    
    func sendMessage(_ content: String) async {
        guard !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        let userMessage = ChatMessage(
            id: UUID(),
            content: content,
            isFromUser: true,
            timestamp: Date()
        )
        
        messages.append(userMessage)
        saveMessages() // Auto-save when message is added
        
        print("📤 Sending message: \(content)")
        print("📤 Message sending started: \(content)")
        
        // Check subscription before generating AI response
        if !subscriptionManager.canUseAI() {
            showSubscriptionAlert = true
            subscriptionAlertMessage = "Subscription required to use AI features.\nPlease start subscription from settings."
            return
        }
        
        await generateAIResponse(for: content)
    }
    
    private func generateAIResponse(for userMessage: String) async {
        guard let persona = selectedPersona else { return }
        
        isTyping = true
        
        do {
            print("🤖 AI response generation in progress...")
            print("🤖 AI response generation started: \(userMessage)")
            
            // Check AI configuration
            let aiConfig = AIConfigManager.shared.currentConfig
            print("🤖 AI configuration check: enabled=\(aiConfig.isAIEnabled)")
            
            // Check subscription status
            let canUseAI = subscriptionManager.canUseAI()
            print("🤖 Subscription check: status=\(subscriptionManager.subscriptionStatus.displayName), available=\(canUseAI)")
            
            if !canUseAI {
                print("❌ Subscription required")
                showSubscriptionAlert = true
                subscriptionAlertMessage = "Subscription required to use AI features.\nPlease start subscription from settings."
                isTyping = false
                return
            }
            
            print("🤖 AI response generation executing...")
            
            let response = try await aiChatService.generateResponse(
                persona: persona,
                conversationHistory: messages,
                userMessage: userMessage
            )
            
            let aiMessage = ChatMessage(
                id: UUID(),
                content: response,
                isFromUser: false,
                timestamp: Date()
            )
            
            messages.append(aiMessage)
            saveMessages() // Auto-save when AI response is added
            
            print("✅ AI response generated successfully")
            
        } catch AIChatError.subscriptionRequired {
            showSubscriptionAlert = true
            subscriptionAlertMessage = "Subscription required to use AI features.\nPlease start subscription from settings."
            print("❌ Subscription required for AI features")
            
        } catch AIChatError.aiNotEnabled {
            showError = true
            errorMessage = "AI features are not enabled"
            print("❌ AI features not enabled")
            
        } catch AIChatError.vercelURLNotSet {
            showError = true
            errorMessage = "Vercel URL not configured"
            print("❌ Vercel URL not set")
            
        } catch AIChatError.apiError(let message) {
            showError = true
            errorMessage = "API error: \(message)"
            print("❌ API error: \(message)")
            
        } catch AIChatError.networkError {
            showError = true
            errorMessage = "Network error occurred"
            print("❌ Network error")
            
        } catch AIChatError.rateLimitExceeded {
            showError = true
            errorMessage = "Rate limit exceeded. Please try again later."
            print("❌ Rate limit exceeded")
            
        } catch AIChatError.invalidResponse {
            showError = true
            errorMessage = "Invalid response received"
            print("❌ Invalid response")
            
        } catch AIChatError.invalidURL {
            showError = true
            errorMessage = "Invalid URL"
            print("❌ Invalid URL")
            
        } catch AIChatError.serverError(let code) {
            showError = true
            errorMessage = "Server error (status code: \(code))"
            print("❌ Server error: \(code)")
            
        } catch {
            showError = true
            errorMessage = "An unexpected error occurred"
            print("❌ Unexpected error: \(error)")
        }
        
        isTyping = false
    }
    
    func clearChat() {
        messages.removeAll()
        print("🗑️ Chat cleared")
    }
    
    func deleteMessage(_ message: ChatMessage) {
        messages.removeAll { $0.id == message.id }
        print("🗑️ Message deleted: \(message.content.prefix(20))...")
    }
    
    // MARK: - Debug Methods
    
    func printDebugInfo() {
        print("📊 ChatViewModel debug information:")
        print("  - Selected persona: \(selectedPersona?.name ?? "none")")
        print("  - Message count: \(messages.count)")
        print("  - Sending: \(isTyping)")
        print("  - Typing: \(isTyping)")
        print("  - Subscription: \(subscriptionManager.subscriptionStatus.displayName)")
    }
    
    func testAIConnection() async {
        do {
            let success = try await aiChatService.testConnection()
            if success {
                print("✅ AI connection test successful")
            } else {
                print("❌ AI connection test failed")
            }
        } catch {
            print("❌ AI connection test error: \(error)")
        }
    }
    
    // MARK: - Subscription Management
    
    func checkSubscriptionStatus() {
        Task {
            await subscriptionManager.updateSubscriptionStatus()
            print("💬 Subscription status: \(subscriptionManager.subscriptionStatus)")
        }
    }
    
    // MARK: - Conversation Management
    
    func clearConversation() async {
        messages = []
        currentMessage = ""
        saveMessages()
        print("🗑️ Conversation cleared")
    }
    
    func loadConversation(for persona: UserPersona) {
        selectedPersona = persona
        loadMessagesForPersona(persona)
        currentMessage = ""
        print("💬 Conversation loaded for persona: \(persona.name)")
    }
    
    // MARK: - Persistence Methods
    
    private func loadPersistedData() {
        // Load current persona
        if let personaId = UserDefaults.standard.string(forKey: currentPersonaKey),
           let persona = personaManager.getPersona(by: personaId) {
            selectedPersona = persona
            loadMessagesForPersona(persona)
            print("📱 Loaded persisted persona: \(persona.name)")
        }
    }
    
    private func loadMessagesForPersona(_ persona: UserPersona) {
        let key = "chat_messages_\(persona.id)"
        if let data = UserDefaults.standard.data(forKey: key) {
            do {
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .secondsSince1970
                let loadedMessages = try decoder.decode([ChatMessage].self, from: data)
                messages = loadedMessages
                print("📱 Loaded \(messages.count) messages for persona: \(persona.name)")
            } catch {
                print("❌ Failed to load messages for persona \(persona.name): \(error)")
                messages = []
            }
        } else {
            messages = []
            print("📱 No saved messages found for persona: \(persona.name)")
        }
    }
    
    private func saveMessages() {
        guard let persona = selectedPersona else { return }
        
        let key = "chat_messages_\(persona.id)"
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .secondsSince1970
            let data = try encoder.encode(messages)
            UserDefaults.standard.set(data, forKey: key)
            
            // Save current persona ID
            UserDefaults.standard.set(persona.id, forKey: currentPersonaKey)
            
            print("💾 Saved \(messages.count) messages for persona: \(persona.name)")
        } catch {
            print("❌ Failed to save messages for persona \(persona.name): \(error)")
        }
    }
    
    func saveOnAppWillTerminate() {
        saveMessages()
        print("💾 Messages saved on app termination")
    }
    
    func switchToPersona(_ persona: UserPersona) {
        selectedPersona = persona
        loadConversation(for: persona)
        print("🔄 Switched to persona: \(persona.name)")
    }
    
    func loadAIConversation() {
        // Load AI conversation without specific persona
        messages = []
        currentMessage = ""
        print("🤖 AI conversation loaded")
    }
    

    
    // MARK: - Error Handling
    
    func handleError(_ error: Error) {
        if let aiError = error as? AIChatError {
            switch aiError {
            case .subscriptionRequired:
                showSubscriptionAlert = true
                subscriptionAlertMessage = "Subscription required to use AI features.\nPlease start subscription from settings."
            case .aiNotEnabled:
                showError = true
                errorMessage = "AI features are not enabled"
            case .vercelURLNotSet:
                showError = true
                errorMessage = "Vercel URL not configured"
            case .apiError(let message):
                showError = true
                errorMessage = "API error: \(message)"
            case .networkError:
                showError = true
                errorMessage = "Network error occurred"
            case .rateLimitExceeded:
                showError = true
                errorMessage = "Rate limit exceeded. Please try again later."
            case .invalidResponse:
                showError = true
                errorMessage = "Invalid response received"
            case .invalidURL:
                showError = true
                errorMessage = "Invalid URL"
            case .serverError(let code):
                showError = true
                errorMessage = "Server error (status code: \(code))"
            }
        } else {
            showError = true
            errorMessage = "An unexpected error occurred"
        }
        
        print("❌ Send error: \(errorMessage)")
    }
}

// MARK: - Extensions

extension ChatViewModel {
    var canUseAI: Bool {
        return subscriptionManager.canUseAI()
    }
    
    var isSubscriptionActive: Bool {
        return subscriptionManager.subscriptionStatus == .active
    }
    
    var isTrialActive: Bool {
        return subscriptionManager.subscriptionStatus == .trial
    }
    
    var trialDaysLeft: Int {
        return subscriptionManager.trialDaysLeft
    }
}

// MARK: - Error Types

enum ChatViewModelError: LocalizedError {
    case aiNotEnabled
    case subscriptionRequired
    case networkError
    case invalidResponse
    
    var errorDescription: String? {
        switch self {
        case .aiNotEnabled:
            return "AI features are not enabled"
        case .subscriptionRequired:
            return "Subscription required to use AI features"
        case .networkError:
            return "Network error occurred"
        case .invalidResponse:
            return "Invalid response received"
        }
    }
}
