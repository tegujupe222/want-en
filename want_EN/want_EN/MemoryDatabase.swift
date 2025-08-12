import Foundation

class MemoryDatabase {
    private let memories: [MemoryKeyword] = MemoryKeyword.defaultMemories
    
    func findMemoryResponse(for message: String) -> String? {
        let lowercasedMessage = message.lowercased()
        
        // Execute keyword matching
        for memory in memories {
            // Check main keyword
            if lowercasedMessage.contains(memory.keyword) {
                return selectResponse(from: memory)
            }
            
            // Check related keywords
            for relatedWord in memory.relatedWords {
                if lowercasedMessage.contains(relatedWord.lowercased()) {
                    return selectResponse(from: memory)
                }
            }
        }
        
        return nil
    }
    
    private func selectResponse(from memory: MemoryKeyword) -> String {
        // Select response based on emotional weight
        if memory.emotionalWeight > 0.8 {
            // Special response for important memories
            return memory.memoryResponses.randomElement() ?? "I cherish that memory"
        } else {
            return memory.memoryResponses.randomElement() ?? "I remember that"
        }
    }
    
    func addCustomMemory(keyword: String,
                        relatedWords: [String] = [],
                        responses: [String],
                        emotionalWeight: Double = 0.5) {
        // In a real app, persistence would be needed
        // This is a sample implementation
        let newMemory = MemoryKeyword(
            keyword: keyword,
            relatedWords: relatedWords,
            memoryResponses: responses,
            emotionalWeight: emotionalWeight
        )
        
        // In implementation, add to array and save to UserDefaults or Core Data
        print("Added new memory: \(newMemory.keyword)")
    }
    
    func getAllMemories() -> [MemoryKeyword] {
        return memories
    }
    
    func searchMemories(containing text: String) -> [MemoryKeyword] {
        let lowercasedText = text.lowercased()
        
        return memories.filter { memory in
            memory.keyword.lowercased().contains(lowercasedText) ||
            memory.relatedWords.contains { $0.lowercased().contains(lowercasedText) }
        }
    }
}
