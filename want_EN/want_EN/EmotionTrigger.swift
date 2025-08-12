import Foundation

struct EmotionTrigger: Identifiable, Codable {
    let id: UUID
    let emotion: String
    let emoji: String
    let keywords: [String]
    let responses: [String]  // ✅ Added: response text
    let followUpQuestions: [String]  // ✅ Added: follow-up questions
    let intensity: Int // 1-10
    
    init(emotion: String,
         emoji: String,
         keywords: [String],
         responses: [String] = [],
         followUpQuestions: [String] = [],
         intensity: Int = 5) {
        self.id = UUID()  // ✅ Fix: generate UUID in init
        self.emotion = emotion
        self.emoji = emoji
        self.keywords = keywords
        self.responses = responses
        self.followUpQuestions = followUpQuestions
        self.intensity = intensity
    }
    
    // MARK: - Default Triggers (Enhanced)
    
    static let defaultTriggers: [EmotionTrigger] = [
        // Loneliness
        EmotionTrigger(
            emotion: "lonely",
            emoji: "🕊",
            keywords: ["lonely", "alone", "miss you", "solitude", "by myself", "lonesome"],
            responses: [
                "I'm here for you, always",
                "You're not alone",
                "I'm thinking of you",
                "It's okay, I'm here",
                "Talk to me anytime",
                "We're connected in heart"
            ],
            followUpQuestions: [
                "What are you thinking about?",
                "Is there anything you want to talk about?",
                "How was your day today?",
                "Do you remember when we were together?"
            ],
            intensity: 7
        ),
        
        // Want to talk
        EmotionTrigger(
            emotion: "want to talk",
            emoji: "💬",
            keywords: ["want to talk", "listen", "advice", "chat", "talk", "conversation"],
            responses: [
                "Tell me anything",
                "I'm always listening",
                "What kind of story? I'm looking forward to it",
                "I like your stories",
                "Take your time",
                "What should we talk about?"
            ],
            followUpQuestions: [
                "How have you been lately?",
                "Any interesting stories?",
                "Tell me how you're feeling now",
                "Is there anything troubling you?"
            ],
            intensity: 6
        ),
        
        // Gratitude and joy
        EmotionTrigger(
            emotion: "thank you",
            emoji: "🌈",
            keywords: ["thank you", "grateful", "happy", "helped", "thanks"],
            responses: [
                "You're welcome",
                "Your smile is the best",
                "I'm glad I could help",
                "I'm always here for you",
                "I'll do anything for you",
                "I'm glad I could be useful"
            ],
            followUpQuestions: [
                "Is there anything else?",
                "What should we do next time?",
                "You seem happy",
                "Let's do something together again"
            ],
            intensity: 8
        ),
        
        // Fatigue and stress
        EmotionTrigger(
            emotion: "tired",
            emoji: "😴",
            keywords: ["tired", "exhausted", "fatigue", "hard", "dull", "sleepy"],
            responses: [
                "Good job",
                "Take a good rest",
                "Don't push yourself too hard",
                "You're working hard",
                "Take care of yourself",
                "Let's take a short break",
                "Thank you for your hard work today"
            ],
            followUpQuestions: [
                "What happened today?",
                "Did you eat properly?",
                "Are you getting enough sleep?",
                "Is there anything I can help with?"
            ],
            intensity: 5
        ),
        
        // Happiness and joy
        EmotionTrigger(
            emotion: "happy",
            emoji: "😊",
            keywords: ["happy", "joy", "fun", "blessed", "pleasure", "happy"],
            responses: [
                "That's great!",
                "I'm happy to see your smile",
                "I'm glad you seem happy",
                "Let me share your joy",
                "That's wonderful",
                "I'm happy when you're happy"
            ],
            followUpQuestions: [
                "What happened? Tell me in detail",
                "How do you feel?",
                "You want to tell someone, right?",
                "I hope you have more happy moments"
            ],
            intensity: 8
        ),
        
        // Worry and anxiety
        EmotionTrigger(
            emotion: "worried",
            emoji: "😰",
            keywords: ["worried", "anxious", "scared", "nervous", "tension", "troubled"],
            responses: [
                "It's okay",
                "Let's think about it together",
                "You can overcome this",
                "I'm here for you",
                "Don't worry",
                "It'll work out",
                "I'm on your side"
            ],
            followUpQuestions: [
                "What are you worried about?",
                "Try talking about it, it might help",
                "What do you think we should do?",
                "Don't keep it to yourself"
            ],
            intensity: 6
        )
    ]
    
    // MARK: - Helper Methods
    
    static func findTrigger(for text: String) -> EmotionTrigger? {
        let lowercaseText = text.lowercased()
        
        return defaultTriggers.first { trigger in
            trigger.keywords.contains { keyword in
                lowercaseText.contains(keyword.lowercased())
            }
        }
    }
    
    static func findAllTriggers(for text: String) -> [EmotionTrigger] {
        let lowercaseText = text.lowercased()
        
        return defaultTriggers.filter { trigger in
            trigger.keywords.contains { keyword in
                lowercaseText.contains(keyword.lowercased())
            }
        }
    }
    
    static func getEmotionStrength(for text: String) -> Int {
        let triggers = findAllTriggers(for: text)
        
        if triggers.isEmpty {
            return 0
        }
        
        let totalIntensity = triggers.reduce(0) { $0 + $1.intensity }
        return min(totalIntensity / triggers.count, 10)
    }
    
    // MARK: - Response Methods
    
    func getRandomResponse() -> String {
        return responses.randomElement() ?? "I see"
    }
    
    func getRandomFollowUp() -> String? {
        return followUpQuestions.randomElement()
    }
    
    func getFullResponse() -> String {
        let response = getRandomResponse()
        
        if let followUp = getRandomFollowUp(), Bool.random() {
            return "\(response) \(followUp)"
        } else {
            return response
        }
    }
    
    // MARK: - Custom Triggers Support
    
    static func createCustomTrigger(
        emotion: String,
        emoji: String,
        keywords: [String],
        responses: [String] = [],
        followUpQuestions: [String] = [],
        intensity: Int = 5
    ) -> EmotionTrigger {
        return EmotionTrigger(
            emotion: emotion,
            emoji: emoji,
            keywords: keywords,
            responses: responses,
            followUpQuestions: followUpQuestions,
            intensity: max(1, min(intensity, 10)) // Limit to 1-10 range
        )
    }
    
    var displayText: String {
        return "\(emoji) \(emotion)"
    }
    
    var keywordText: String {
        return keywords.joined(separator: ", ")
    }
}

// MARK: - Extensions

extension EmotionTrigger: Equatable {
    static func == (lhs: EmotionTrigger, rhs: EmotionTrigger) -> Bool {
        return lhs.emotion == rhs.emotion && lhs.emoji == rhs.emoji
    }
}

extension EmotionTrigger: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(emotion)
        hasher.combine(emoji)
    }
}

// MARK: - Manager Class

class EmotionTriggerManager: ObservableObject {
    @Published var customTriggers: [EmotionTrigger] = []
    
    private let userDefaults = UserDefaults.standard
    private let customTriggersKey = "custom_emotion_triggers"
    
    init() {
        loadCustomTriggers()
    }
    
    var allTriggers: [EmotionTrigger] {
        return EmotionTrigger.defaultTriggers + customTriggers
    }
    
    func addCustomTrigger(_ trigger: EmotionTrigger) {
        customTriggers.append(trigger)
        saveCustomTriggers()
    }
    
    func removeCustomTrigger(_ trigger: EmotionTrigger) {
        customTriggers.removeAll { $0.id == trigger.id }
        saveCustomTriggers()
    }
    
    func findTrigger(for text: String) -> EmotionTrigger? {
        let lowercaseText = text.lowercased()
        
        // Prioritize custom triggers
        if let customTrigger = customTriggers.first(where: { trigger in
            trigger.keywords.contains { keyword in
                lowercaseText.contains(keyword.lowercased())
            }
        }) {
            return customTrigger
        }
        
        // Search default triggers
        return EmotionTrigger.findTrigger(for: text)
    }
    
    func getEmotionResponse(for emotion: String) -> String {
        guard let trigger = allTriggers.first(where: { $0.emotion == emotion }) else {
            return "I understand how you feel"
        }
        
        return trigger.getFullResponse()
    }
    
    func detectEmotionInMessage(_ message: String) -> String? {
        if let trigger = findTrigger(for: message) {
            return trigger.getFullResponse()
        }
        return nil
    }
    
    private func saveCustomTriggers() {
        do {
            let data = try JSONEncoder().encode(customTriggers)
            userDefaults.set(data, forKey: customTriggersKey)
        } catch {
            print("❌ Custom trigger save error: \(error)")
        }
    }
    
    private func loadCustomTriggers() {
        guard let data = userDefaults.data(forKey: customTriggersKey) else { return }
        
        do {
            customTriggers = try JSONDecoder().decode([EmotionTrigger].self, from: data)
        } catch {
            print("❌ Custom trigger load error: \(error)")
        }
    }
}
