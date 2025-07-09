import Foundation

class EnhancedMemoryDatabase {
    private let baseMemoryDatabase = MemoryDatabase()
    private var learnedPhrases: [String: [String]] = [:]
    private var conversationHistory: [ChatMessage] = []
    private let maxHistorySize = 1000
    
    init() {
        loadLearnedPhrases()
    }
    
    // LINEトーク履歴から学習したデータを統合
    func integrateLearningData(from analysisResult: AnalysisResult) {
        // 分析結果からカスタムメモリーを作成
        for phrase in analysisResult.commonPhrases {
            addLearnedPhrase(phrase, responses: generateResponsesForPhrase(phrase))
        }
        
        // 話題に基づくメモリーキーワードを追加
        for topic in analysisResult.favoriteTopics {
            addTopicMemory(topic, from: analysisResult)
        }
        
        saveLearnedPhrases()
    }
    
    func findMemoryResponse(for message: String) -> String? {
        // まず学習済みフレーズをチェック
        if let learnedResponse = findLearnedResponse(for: message) {
            return learnedResponse
        }
        
        // 従来のメモリー検索
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
        // フレーズに基づいて適切な応答を生成
        switch phrase {
        case let p where p.contains("ありがとう"):
            return ["どういたしまして", "喜んでもらえて嬉しいよ", "いつでも力になるからね"]
        case let p where p.contains("疲れた"):
            return ["お疲れさま", "ゆっくり休んで", "無理しないでね"]
        case let p where p.contains("楽しい"):
            return ["良かったね！", "君の笑顔が見れて嬉しい", "一緒に楽しもう"]
        case let p where p.contains("そうだね"):
            return ["そうだね", "わかるよ", "同感だよ"]
        default:
            return ["そうなんだね", "なるほど", "そう思うよ"]
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
        
        // 実際の実装では、カスタムメモリーを永続化
        print("カスタムメモリーを追加: \(topic)")
    }
    
    private func generateTopicResponses(for topic: String, style: String) -> [String] {
        let baseResponses: [String]
        
        switch topic {
        case "仕事":
            baseResponses = ["仕事、お疲れさま", "頑張ってるね", "仕事のことなら何でも聞くよ"]
        case "映画":
            baseResponses = ["どんな映画を見たの？", "映画の話、好きだよ", "また一緒に見たいな"]
        case "料理":
            baseResponses = ["美味しそうだね", "料理上手だね", "今度作ってもらいたいな"]
        default:
            baseResponses = ["その話、興味深いね", "もっと聞かせて", "君の話は面白いよ"]
        }
        
        // 話し方のスタイルに合わせて調整
        if style.contains("丁寧") {
            return baseResponses.map { $0.replacingOccurrences(of: "だね", with: "ですね") }
        } else if style.contains("親しみやすい") {
            return baseResponses.map { $0 + "！" }
        }
        
        return baseResponses
    }
    
    private func getRelatedWords(for topic: String) -> [String] {
        let topicKeywords: [String: [String]] = [
            "仕事": ["職場", "会社", "上司", "同僚", "プロジェクト", "残業"],
            "映画": ["シネマ", "ドラマ", "俳優", "監督", "ストーリー"],
            "料理": ["レシピ", "食材", "レストラン", "美味しい", "作る"],
            "音楽": ["歌", "アーティスト", "ライブ", "コンサート", "楽器"],
            "旅行": ["観光", "ホテル", "電車", "景色", "写真"]
        ]
        
        return topicKeywords[topic] ?? []
    }
    
    // 会話履歴から学習
    func learnFromConversation(_ messages: [ChatMessage]) {
        conversationHistory.append(contentsOf: messages)
        
        // 履歴サイズを制限
        if conversationHistory.count > maxHistorySize {
            conversationHistory = Array(conversationHistory.suffix(maxHistorySize))
        }
        
        // パターン学習を実行
        analyzeConversationPatterns()
    }
    
    private func analyzeConversationPatterns() {
        // ユーザーメッセージとBotの応答ペアを分析
        for i in 0..<conversationHistory.count - 1 {
            let userMessage = conversationHistory[i]
            let botMessage = conversationHistory[i + 1]
            
            if userMessage.isFromUser && !botMessage.isFromUser {
                learnResponsePattern(userInput: userMessage.content, botResponse: botMessage.content)
            }
        }
    }
    
    private func learnResponsePattern(userInput: String, botResponse: String) {
        // キーワードベースの学習
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
        // 簡単なキーワード抽出
        let commonWords = ["は", "が", "を", "に", "で", "と", "の", "だ", "です", "ます"]
        let words = text.components(separatedBy: .whitespacesAndNewlines)
        
        return words.filter { word in
            word.count > 1 && !commonWords.contains(word)
        }
    }
    
    // 学習データの永続化
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
    
    // 学習データのクリア
    func clearLearnedData() {
        learnedPhrases.removeAll()
        conversationHistory.removeAll()
        UserDefaults.standard.removeObject(forKey: "learnedPhrases")
    }
    
    // 学習状況の取得
    func getLearningStats() -> (phraseCount: Int, conversationCount: Int) {
        return (learnedPhrases.count, conversationHistory.count)
    }
    
    // ベースのメモリーデータベース機能を公開
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
