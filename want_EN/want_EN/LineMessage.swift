import Foundation
import SwiftUI

struct LineMessage: Codable {
    let timestamp: String
    let sender: String
    let message: String
    let messageType: String?
}

struct AnalysisResult {
    let detectedName: String
    let commonPhrases: [String]
    let communicationStyle: String
    let personality: [String]
    let favoriteTopics: [String]
    let emotionalTone: String
    let responsePatterns: [String]
    let messageFrequency: String
}

class LineAnalyzer: ObservableObject {
    @Published var isAnalyzing = false
    @Published var analysisProgress: Double = 0.0
    @Published var analysisResult: AnalysisResult?
    @Published var errorMessage: String?
    
    func analyzeLineHistory(fileContent: String) {
        isAnalyzing = true
        analysisProgress = 0.0
        errorMessage = nil
        
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let result = try self.performAnalysis(fileContent: fileContent)
                
                DispatchQueue.main.async {
                    self.analysisResult = result
                    self.isAnalyzing = false
                    self.analysisProgress = 1.0
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = error.localizedDescription
                    self.isAnalyzing = false
                }
            }
        }
    }
    
    private func performAnalysis(fileContent: String) throws -> AnalysisResult {
        // ステップ1: テキストファイルの解析 (20%)
        updateProgress(0.2)
        let messages = try parseLineText(fileContent)
        
        // ステップ2: 送信者の特定 (40%)
        updateProgress(0.4)
        let targetSender = identifyTargetSender(from: messages)
        let targetMessages = messages.filter { $0.sender == targetSender }
        
        // ステップ3: 言語パターン分析 (60%)
        updateProgress(0.6)
        let phrases = analyzePhrases(from: targetMessages)
        let style = analyzeCommunicationStyle(from: targetMessages)
        
        // ステップ4: 性格・感情分析 (80%)
        updateProgress(0.8)
        let personality = analyzePersonality(from: targetMessages)
        let emotionalTone = analyzeEmotionalTone(from: targetMessages)
        
        // ステップ5: トピック分析 (100%)
        updateProgress(1.0)
        let topics = analyzeTopics(from: targetMessages)
        let patterns = analyzeResponsePatterns(from: targetMessages)
        let frequency = analyzeMessageFrequency(from: targetMessages)
        
        return AnalysisResult(
            detectedName: targetSender,
            commonPhrases: phrases,
            communicationStyle: style,
            personality: personality,
            favoriteTopics: topics,
            emotionalTone: emotionalTone,
            responsePatterns: patterns,
            messageFrequency: frequency
        )
    }
    
    private func updateProgress(_ progress: Double) {
        DispatchQueue.main.async {
            self.analysisProgress = progress
        }
    }
    
    private func parseLineText(_ content: String) throws -> [LineMessage] {
        var messages: [LineMessage] = []
        let lines = content.components(separatedBy: .newlines)
        
        for line in lines {
            if let message = parseLineMessage(line) {
                messages.append(message)
            }
        }
        
        if messages.isEmpty {
            throw AnalysisError.noMessagesFound
        }
        
        return messages
    }
    
    private func parseLineMessage(_ line: String) -> LineMessage? {
        // LINEのエクスポート形式を解析
        // 例: "2024/01/15(月) 14:30:25 田中太郎 こんにちは！元気？"
        
        let patterns = [
            // 標準的なLINE形式
            #"(\d{4}/\d{2}/\d{2})\([月火水木金土日]\)\s(\d{2}:\d{2}:\d{2})\s([^\s]+)\s(.+)"#,
            // 簡略形式
            #"(\d{2}:\d{2})\s([^\s]+)\s(.+)"#,
            // タブ区切り形式
            #"([^\t]+)\t([^\t]+)\t(.+)"#
        ]
        
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern),
               let match = regex.firstMatch(in: line, range: NSRange(location: 0, length: line.count)) {
                
                let groups = (0..<match.numberOfRanges).map { index in
                    let range = match.range(at: index)
                    return range.location != NSNotFound ? String(line[Range(range, in: line)!]) : ""
                }
                
                if groups.count >= 4 {
                    return LineMessage(
                        timestamp: groups[1],
                        sender: groups[groups.count - 2],
                        message: groups[groups.count - 1],
                        messageType: "text"
                    )
                }
            }
        }
        
        return nil
    }
    
    private func identifyTargetSender(from messages: [LineMessage]) -> String {
        // 送信者ごとのメッセージ数をカウント
        let senderCounts = Dictionary(grouping: messages, by: { $0.sender })
            .mapValues { $0.count }
        
        // 自分以外で最もメッセージ数が多い送信者を対象とする
        // "私" "自分" "me" などの自分を示すキーワードを除外
        let excludeKeywords = ["私", "自分", "me", "Me", "ME"]
        
        let targetSender = senderCounts
            .filter { !excludeKeywords.contains($0.key) }
            .max(by: { $0.value < $1.value })?
            .key ?? messages.first?.sender ?? "相手"
        
        return targetSender
    }
    
    private func analyzePhrases(from messages: [LineMessage]) -> [String] {
        let messageTexts = messages.map { $0.message }
        var phraseFrequency: [String: Int] = [:]
        
        // 短いフレーズ（2-4文字）の頻度分析
        for message in messageTexts {
            let phrases = extractPhrases(from: message)
            for phrase in phrases {
                phraseFrequency[phrase, default: 0] += 1
            }
        }
        
        // 頻度の高い順に並べて上位10個を返す
        return phraseFrequency
            .filter { $0.value >= 2 } // 2回以上出現
            .sorted { $0.value > $1.value }
            .prefix(10)
            .map { $0.key }
    }
    
    private func extractPhrases(from text: String) -> [String] {
        var phrases: [String] = []
        
        // 一般的な口癖パターン
        let patterns = [
            "そうだね", "なるほど", "わかる", "いいね", "ありがとう",
            "お疲れ", "頑張って", "大丈夫", "楽しい", "嬉しい",
            "すごい", "やばい", "めっちゃ", "かなり", "ちょっと"
        ]
        
        for pattern in patterns {
            if text.contains(pattern) {
                phrases.append(pattern)
            }
        }
        
        return phrases
    }
    
    private func analyzeCommunicationStyle(from messages: [LineMessage]) -> String {
        let messageTexts = messages.map { $0.message }
        let totalMessages = messageTexts.count
        
        if totalMessages == 0 { return "普通の口調" }
        
        // 敬語の使用頻度
        let politeWords = ["です", "ます", "ございます", "いたします"]
        let politeCount = messageTexts.filter { message in
            politeWords.contains { message.contains($0) }
        }.count
        
        // 感嘆詞の使用頻度
        let exclamationCount = messageTexts.filter { $0.contains("!") || $0.contains("！") }.count
        
        // 絵文字の使用頻度
        let emojiCount = messageTexts.filter { message in
            message.unicodeScalars.contains { $0.properties.isEmoji }
        }.count
        
        let politeRatio = Double(politeCount) / Double(totalMessages)
        let exclamationRatio = Double(exclamationCount) / Double(totalMessages)
        let emojiRatio = Double(emojiCount) / Double(totalMessages)
        
        if politeRatio > 0.3 {
            return "丁寧で礼儀正しい口調"
        } else if exclamationRatio > 0.4 || emojiRatio > 0.3 {
            return "親しみやすく元気な口調"
        } else if emojiRatio > 0.1 {
            return "フレンドリーな口調"
        } else {
            return "落ち着いた自然な口調"
        }
    }
    
    private func analyzePersonality(from messages: [LineMessage]) -> [String] {
        let messageTexts = messages.map { $0.message }
        var personality: [String] = []
        
        // 性格特性のキーワード分析
        let personalityKeywords: [String: [String]] = [
            "優しい": ["ありがとう", "大丈夫", "心配", "気をつけて", "お疲れ"],
            "明るい": ["楽しい", "嬉しい", "いいね", "！", "😊", "😄"],
            "思いやりがある": ["大丈夫？", "無理しない", "気をつけて", "お疲れさま"],
            "ユーモアがある": ["笑", "www", "爆笑", "面白い", "😂"],
            "真面目": ["仕事", "勉強", "頑張", "努力", "責任"],
            "聞き上手": ["そうなんだ", "なるほど", "へー", "詳しく", "教えて"]
        ]
        
        for (trait, keywords) in personalityKeywords {
            let matchCount = messageTexts.filter { message in
                keywords.contains { message.contains($0) }
            }.count
            
            if Double(matchCount) / Double(messageTexts.count) > 0.1 {
                personality.append(trait)
            }
        }
        
        return personality.isEmpty ? ["優しい"] : personality
    }
    
    private func analyzeEmotionalTone(from messages: [LineMessage]) -> String {
        let messageTexts = messages.map { $0.message }
        
        let positiveWords = ["嬉しい", "楽しい", "いいね", "素晴らしい", "最高"]
        let negativeWords = ["悲しい", "辛い", "疲れた", "大変", "困った"]
        
        let positiveCount = messageTexts.filter { message in
            positiveWords.contains { message.contains($0) }
        }.count
        
        let negativeCount = messageTexts.filter { message in
            negativeWords.contains { message.contains($0) }
        }.count
        
        if positiveCount > negativeCount * 2 {
            return "ポジティブで前向き"
        } else if negativeCount > positiveCount * 2 {
            return "思慮深く慎重"
        } else {
            return "バランスの取れた"
        }
    }
    
    private func analyzeTopics(from messages: [LineMessage]) -> [String] {
        let messageTexts = messages.map { $0.message }
        var topicCounts: [String: Int] = [:]
        
        let topicKeywords: [String: [String]] = [
            "仕事": ["仕事", "会社", "職場", "上司", "同僚", "残業"],
            "家族": ["家族", "両親", "子ども", "家", "実家"],
            "趣味": ["映画", "音楽", "読書", "ゲーム", "スポーツ", "料理"],
            "日常": ["今日", "昨日", "明日", "朝", "夜", "食事"],
            "健康": ["体調", "病気", "疲れた", "元気", "健康"],
            "恋愛": ["彼氏", "彼女", "恋人", "デート", "好き"],
            "友人": ["友達", "飲み会", "遊び", "会う", "久しぶり"]
        ]
        
        for (topic, keywords) in topicKeywords {
            let count = messageTexts.filter { message in
                keywords.contains { message.contains($0) }
            }.count
            
            if count > 0 {
                topicCounts[topic] = count
            }
        }
        
        return topicCounts
            .sorted { $0.value > $1.value }
            .prefix(5)
            .map { $0.key }
    }
    
    private func analyzeResponsePatterns(from messages: [LineMessage]) -> [String] {
        // 応答パターンの分析（簡略版）
        return [
            "そうなんだね",
            "わかるよ",
            "頑張って",
            "お疲れさま",
            "ありがとう"
        ]
    }
    
    private func analyzeMessageFrequency(from messages: [LineMessage]) -> String {
        let messageCount = messages.count
        
        if messageCount > 1000 {
            return "とても親しい関係"
        } else if messageCount > 500 {
            return "よく話す関係"
        } else if messageCount > 100 {
            return "適度に連絡を取る関係"
        } else {
            return "たまに連絡を取る関係"
        }
    }
}

enum AnalysisError: LocalizedError {
    case noMessagesFound
    case invalidFormat
    case fileTooLarge
    
    var errorDescription: String? {
        switch self {
        case .noMessagesFound:
            return "メッセージが見つかりませんでした。ファイル形式を確認してください。"
        case .invalidFormat:
            return "サポートされていないファイル形式です。"
        case .fileTooLarge:
            return "ファイルサイズが大きすぎます。"
        }
    }
}
