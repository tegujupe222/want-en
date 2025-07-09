import Foundation
import SwiftUI

struct UserPersona: Identifiable, Codable, Equatable {
    let id: String
    var name: String
    var relationship: String
    var personality: [String]
    var speechStyle: String
    var catchphrases: [String]
    var favoriteTopics: [String]
    var mood: PersonaMood
    var customization: PersonaCustomization
    
    // 初期化
    init(
        id: String = UUID().uuidString,
        name: String,
        relationship: String,
        personality: [String],
        speechStyle: String,
        catchphrases: [String],
        favoriteTopics: [String],
        mood: PersonaMood = .neutral,
        customization: PersonaCustomization = PersonaCustomization()
    ) {
        self.id = id
        self.name = name
        self.relationship = relationship
        self.personality = personality
        self.speechStyle = speechStyle
        self.catchphrases = catchphrases
        self.favoriteTopics = favoriteTopics
        self.mood = mood
        self.customization = customization
    }
    
    // Equatable適合
    static func == (lhs: UserPersona, rhs: UserPersona) -> Bool {
        return lhs.id == rhs.id
    }
    
    // 表示用のプロパティ
    var displayName: String {
        return name.isEmpty ? "名前なし" : name
    }
    
    var moodEmoji: String {
        return mood.emoji
    }
    
    var personalityText: String {
        return personality.joined(separator: " • ")
    }
    
    var catchphraseText: String {
        return catchphrases.joined(separator: " / ")
    }
    
    var topicsText: String {
        return favoriteTopics.joined(separator: " • ")
    }
    
    // MARK: - Static Methods
    
    static var defaultPersona: UserPersona {
        return UserPersona(
            name: "アシスタント",
            relationship: "サポーター",
            personality: ["親しみやすい", "頼れる", "優しい"],
            speechStyle: "丁寧で親しみやすい口調",
            catchphrases: ["お疲れさまです", "いつでもサポートします"],
            favoriteTopics: ["日常会話", "相談事", "雑談"],
            mood: .happy,
            customization: PersonaCustomization.safeDefault
        )
    }
}

// MARK: - PersonaMood

enum PersonaMood: String, CaseIterable, Codable {
    case happy = "happy"
    case sad = "sad"
    case excited = "excited"
    case calm = "calm"
    case anxious = "anxious"
    case angry = "angry"
    case neutral = "neutral"
    
    var displayName: String {
        switch self {
        case .happy:
            return "幸せ"
        case .sad:
            return "悲しい"
        case .excited:
            return "興奮"
        case .calm:
            return "穏やか"
        case .anxious:
            return "不安"
        case .angry:
            return "怒り"
        case .neutral:
            return "普通"
        }
    }
    
    var emoji: String {
        switch self {
        case .happy:
            return "😊"
        case .sad:
            return "😢"
        case .excited:
            return "🤩"
        case .calm:
            return "😌"
        case .anxious:
            return "😰"
        case .angry:
            return "😠"
        case .neutral:
            return "😐"
        }
    }
    
    var color: Color {
        switch self {
        case .happy:
            return .yellow
        case .sad:
            return .blue
        case .excited:
            return .orange
        case .calm:
            return .green
        case .anxious:
            return .purple
        case .angry:
            return .red
        case .neutral:
            return .gray
        }
    }
}
