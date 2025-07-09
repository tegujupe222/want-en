import Foundation

class MemoryDatabase {
    private let memories: [MemoryKeyword] = MemoryKeyword.defaultMemories
    
    func findMemoryResponse(for message: String) -> String? {
        let lowercasedMessage = message.lowercased()
        
        // キーワードマッチングを実行
        for memory in memories {
            // メインキーワードをチェック
            if lowercasedMessage.contains(memory.keyword) {
                return selectResponse(from: memory)
            }
            
            // 関連キーワードをチェック
            for relatedWord in memory.relatedWords {
                if lowercasedMessage.contains(relatedWord.lowercased()) {
                    return selectResponse(from: memory)
                }
            }
        }
        
        return nil
    }
    
    private func selectResponse(from memory: MemoryKeyword) -> String {
        // 感情的重要度に基づいて応答を選択
        if memory.emotionalWeight > 0.8 {
            // 重要な思い出には特別な応答
            return memory.memoryResponses.randomElement() ?? "その思い出、大切にしてるよ"
        } else {
            return memory.memoryResponses.randomElement() ?? "そのこと、覚えてるよ"
        }
    }
    
    func addCustomMemory(keyword: String,
                        relatedWords: [String] = [],
                        responses: [String],
                        emotionalWeight: Double = 0.5) {
        // 実際のアプリでは永続化が必要
        // ここではサンプル実装
        let newMemory = MemoryKeyword(
            keyword: keyword,
            relatedWords: relatedWords,
            memoryResponses: responses,
            emotionalWeight: emotionalWeight
        )
        
        // 実装時は配列に追加し、UserDefaults や Core Data に保存
        print("新しい思い出を追加: \(newMemory.keyword)")
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
