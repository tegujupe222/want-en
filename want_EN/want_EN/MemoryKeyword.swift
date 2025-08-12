import Foundation

struct MemoryKeyword: Codable, Identifiable {
    var id = UUID()
    let keyword: String
    let relatedWords: [String]
    let memoryResponses: [String]
    let emotionalWeight: Double // 0.0-1.0, memory importance
    
    init(keyword: String,
         relatedWords: [String] = [],
         memoryResponses: [String] = [],
         emotionalWeight: Double = 0.5) {
        self.keyword = keyword
        self.relatedWords = relatedWords
        self.memoryResponses = memoryResponses
        self.emotionalWeight = emotionalWeight
    }
}

extension MemoryKeyword {
    static let defaultMemories = [
        MemoryKeyword(
            keyword: "birthday",
            relatedWords: ["birthday", "celebration", "cake", "present"],
            memoryResponses: [
                "That birthday was special",
                "I can't forget your smile",
                "I want to celebrate together again",
                "It was a wonderful time"
            ],
            emotionalWeight: 0.9
        ),
        MemoryKeyword(
            keyword: "travel",
            relatedWords: ["trip", "sightseeing", "train", "plane", "hotel"],
            memoryResponses: [
                "That trip was fun",
                "I remember the scenery we saw together",
                "I want to go again",
                "Traveling with you was the best"
            ],
            emotionalWeight: 0.8
        ),
        MemoryKeyword(
            keyword: "cooking",
            relatedWords: ["meal", "food", "restaurant", "home cooking", "delicious"],
            memoryResponses: [
                "The food you made was delicious",
                "I miss the time we ate together",
                "I want to have a meal together again",
                "I can't forget that taste"
            ],
            emotionalWeight: 0.7
        ),
        MemoryKeyword(
            keyword: "movie",
            relatedWords: ["cinema", "drama", "anime", "theater"],
            memoryResponses: [
                "We watched that movie together",
                "Your reaction was interesting",
                "Let me know if you have any recommendations",
                "It was a fun time"
            ],
            emotionalWeight: 0.6
        )
    ]
}
