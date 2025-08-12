import Foundation

class EnhancedMemoryDatabase {
    private let baseMemoryDatabase = MemoryDatabase()
    private var learnedPhrases: [String: [String]] = [:]
    private var conversationHistory: [ChatMessage] = []
    private let maxHistorySize = 1000
    
    init() {
        loadLearnedPhrases()
    }
    
    // Integrate learning data from LINE talk history
    func integrateLearningData(from analysisResult: AnalysisResult) {
        // Create custom memories from analysis results
        for phrase in analysisResult.commonPhrases {
            addLearnedPhrase(phrase, responses: generateResponsesForPhrase(phrase))
        }
        
        // Add memory keywords based on topics
        for topic in analysisResult.favoriteTopics {
            addTopicMemory(topic, from: analysisResult)
        }
        
        saveLearnedPhrases()
    }
    
    func findMemoryResponse(for message: String) -> String? {
        // First check learned phrases
        if let learnedResponse = findLearnedResponse(for: message) {
            return learnedResponse
        }
        
        // Traditional memory search
        return baseMemoryDatabase.findMemoryResponse(for: message)
    }
    
    private func findLearnedResponse(for message: String) -> String? {
        let lowercasedMessage = message.lowercased()
        
        for (phrase, responses) in learnedPhrases {
            if lowercasedMessage.contains(phrase.lowercased()) {
                return responses.randomElement()
            }
        }
        
        return nil
    }
    
    private func addLearnedPhrase(_ phrase: String, responses: [String]) {
        learnedPhrases[phrase] = responses
    }
    
    private func generateResponsesForPhrase(_ phrase: String) -> [String] {
        // Generate appropriate responses based on phrase
        switch phrase {
        case let p where p.contains("thank you"):
            return ["You're welcome", "I'm glad I could help", "I'm always here for you"]
        case let p where p.contains("tired"):
            return ["Good job", "Take a rest", "Don't push yourself too hard"]
        case let p where p.contains("fun"):
            return ["That's great!", "I'm happy to see your smile", "Let's have fun together"]
        case let p where p.contains("I see"):
            return ["I see", "I understand", "I agree"]
        default:
            return ["I see", "I understand", "I think so too"]
        }
    }
    
    private func addTopicMemory(_ topic: String, from result: AnalysisResult) {
        let responses = generateTopicResponses(for: topic, style: result.communicationStyle)
        
        _ = MemoryKeyword(
            keyword: topic,
            relatedWords: getRelatedWords(for: topic),
            memoryResponses: responses,
            emotionalWeight: 0.6
        )
        
        // In actual implementation, persist custom memories
        print("Added custom memory: \(topic)")
    }
    
    private func generateTopicResponses(for topic: String, style: String) -> [String] {
        let baseResponses: [String]
        
        switch topic {
        case "work":
            baseResponses = ["Good job with work", "You're working hard", "I'm here to listen about work"]
        case "movie":
            baseResponses = ["What movie did you watch?", "I like talking about movies", "I want to watch together again"]
        case "cooking":
            baseResponses = ["That sounds delicious", "You're good at cooking", "I want you to cook for me next time"]
        default:
            baseResponses = ["That's interesting", "Tell me more", "Your stories are fun"]
        }
        
        // Adjust based on speech style
        if style.contains("polite") {
            return baseResponses.map { $0.replacingOccurrences(of: "だね", with: "ですね") }
        } else if style.contains("friendly") {
            return baseResponses.map { $0 + "!" }
        }
        
        return baseResponses
    }
    
    private func getRelatedWords(for topic: String) -> [String] {
        let topicKeywords: [String: [String]] = [
            "work": ["office", "company", "boss", "colleague", "project", "overtime"],
            "movie": ["cinema", "drama", "actor", "director", "story"],
            "cooking": ["recipe", "ingredients", "restaurant", "delicious", "cook"],
            "music": ["song", "artist", "live", "concert", "instrument"],
            "travel": ["sightseeing", "hotel", "train", "scenery", "photo"]
        ]
        
        return topicKeywords[topic] ?? []
    }
    
    // Learn from conversation history
    func learnFromConversation(_ messages: [ChatMessage]) {
        conversationHistory.append(contentsOf: messages)
        
        // Limit history size
        if conversationHistory.count > maxHistorySize {
            conversationHistory = Array(conversationHistory.suffix(maxHistorySize))
        }
        
        // Execute pattern learning
        analyzeConversationPatterns()
    }
    
    private func analyzeConversationPatterns() {
        // Analyze user message and bot response pairs
        for i in 0..<conversationHistory.count - 1 {
            let userMessage = conversationHistory[i]
            let botMessage = conversationHistory[i + 1]
            
            if userMessage.isFromUser && !botMessage.isFromUser {
                learnResponsePattern(userInput: userMessage.content, botResponse: botMessage.content)
            }
        }
    }
    
    private func learnResponsePattern(userInput: String, botResponse: String) {
        // Keyword-based learning
        let keywords = extractKeywords(from: userInput)
        
        for keyword in keywords {
            if learnedPhrases[keyword] == nil {
                learnedPhrases[keyword] = []
            }
            
            if !learnedPhrases[keyword]!.contains(botResponse) {
                learnedPhrases[keyword]!.append(botResponse)
            }
        }
    }
    
    private func extractKeywords(from text: String) -> [String] {
        // Simple keyword extraction
        let commonWords = ["は", "が", "を", "に", "で", "と", "の", "だ", "です", "ます"]
        let words = text.components(separatedBy: .whitespacesAndNewlines)
        
        return words.filter { word in
            word.count > 1 && !commonWords.contains(word)
        }
    }
    
    // Persist learning data
    private func saveLearnedPhrases() {
        if let data = try? JSONEncoder().encode(learnedPhrases) {
            UserDefaults.standard.set(data, forKey: "learnedPhrases")
        }
    }
    
    private func loadLearnedPhrases() {
        if let data = UserDefaults.standard.data(forKey: "learnedPhrases"),
           let phrases = try? JSONDecoder().decode([String: [String]].self, from: data) {
            learnedPhrases = phrases
        }
    }
    
    // Clear learning data
    func clearLearnedData() {
        learnedPhrases.removeAll()
        conversationHistory.removeAll()
        UserDefaults.standard.removeObject(forKey: "learnedPhrases")
    }
    
    // Get learning statistics
    func getLearningStats() -> (phraseCount: Int, conversationCount: Int) {
        return (learnedPhrases.count, conversationHistory.count)
    }
    
    // Expose base memory database functionality
    func addCustomMemory(keyword: String,
                        relatedWords: [String] = [],
                        responses: [String],
                        emotionalWeight: Double = 0.5) {
        baseMemoryDatabase.addCustomMemory(
            keyword: keyword,
            relatedWords: relatedWords,
            responses: responses,
            emotionalWeight: emotionalWeight
        )
    }
    
    func getAllMemories() -> [MemoryKeyword] {
        return baseMemoryDatabase.getAllMemories()
    }
    
    func searchMemories(containing text: String) -> [MemoryKeyword] {
        return baseMemoryDatabase.searchMemories(containing: text)
    }
}
