import Foundation

struct MemoryKeyword: Codable, Identifiable {
    var id = UUID()
    let keyword: String
    let relatedWords: [String]
    let memoryResponses: [String]
    let emotionalWeight: Double // 0.0-1.0, 思い出の重要度
    
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
            keyword: "誕生日",
            relatedWords: ["バースデー", "お祝い", "ケーキ", "プレゼント"],
            memoryResponses: [
                "あの誕生日は特別だったね",
                "君の笑顔が忘れられない",
                "また一緒にお祝いしたいな",
                "素敵な時間だった"
            ],
            emotionalWeight: 0.9
        ),
        MemoryKeyword(
            keyword: "旅行",
            relatedWords: ["旅", "観光", "電車", "飛行機", "ホテル"],
            memoryResponses: [
                "あの旅行は楽しかったね",
                "一緒に見た景色、覚えてる",
                "また行きたいね",
                "君との旅は最高だった"
            ],
            emotionalWeight: 0.8
        ),
        MemoryKeyword(
            keyword: "料理",
            relatedWords: ["ご飯", "食事", "レストラン", "手料理", "美味しい"],
            memoryResponses: [
                "君の作った料理、美味しかった",
                "一緒に食べた時間が懐かしい",
                "また一緒に食事したいな",
                "あの味が忘れられない"
            ],
            emotionalWeight: 0.7
        ),
        MemoryKeyword(
            keyword: "映画",
            relatedWords: ["シネマ", "ドラマ", "アニメ", "映画館"],
            memoryResponses: [
                "あの映画、一緒に見たね",
                "君の反応が面白かった",
                "またおすすめがあったら教えて",
                "楽しい時間だった"
            ],
            emotionalWeight: 0.6
        )
    ]
}
