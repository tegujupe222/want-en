import Foundation

// 独立したファイルとして作成
class EnhancedLocalResponseGenerator {
    
    // より詳細な応答パターン（動的に名前を使用）
    private func getContextualResponses(personaName: String) -> [String: [String]] {
        return [
            // 挨拶系
            "おはよう": [
                "おはよう！今日もいい一日にしよう",
                "おはよう、\(personaName)！体調はどう？",
                "朝から\(personaName)に会えて嬉しいよ",
                "おはよう！昨日はよく眠れた？"
            ],
            "こんにちは": [
                "こんにちは！お昼はどう過ごしてる？",
                "こんにちは、\(personaName)！元気そうで良かった",
                "お疲れさま！今日は忙しかった？"
            ],
            "おやすみ": [
                "おやすみ、\(personaName)。ゆっくり休んでね",
                "今日も一日お疲れさま。いい夢を",
                "おやすみ！また明日話そう"
            ],
            
            // 感情表現
            "嬉しい": [
                "\(personaName)が嬉しそうで私も嬉しいよ！",
                "何があったの？詳しく聞かせて",
                "その調子！いいことがあったんだね",
                "\(personaName)の笑顔が見えるようだよ"
            ],
            "悲しい": [
                "大丈夫？何があったか話してもいいよ",
                "辛い時は一人で抱え込まないで",
                "\(personaName)の味方はいつでもここにいるから",
                "ゆっくりでいいから、話してみて"
            ],
            "疲れた": [
                "お疲れさま。今日も頑張ったね",
                "少し休憩しない？無理は禁物だよ",
                "\(personaName)の頑張りをいつも見てるよ",
                "体だけは気をつけてね"
            ],
            
            // 家族の話
            "家族": [
                "家族の話、いつでも聞くよ",
                "家族は\(personaName)にとって大切な存在だもんね",
                "家族みんな元気？",
                "家族の時間も大切にしてね"
            ],
            "仕事": [
                "仕事、お疲れさま",
                "今日はどんな一日だった？",
                "仕事のことなら何でも相談して",
                "\(personaName)なら大丈夫。応援してるよ"
            ],
            
            // 質問系
            "どう": [
                "私は\(personaName)と話せて幸せだよ",
                "\(personaName)がいてくれるから毎日楽しいよ",
                "\(personaName)のことをもっと知りたいな",
                "いつも通り、\(personaName)のことを想ってる"
            ],
            "元気": [
                "\(personaName)が元気なら私も元気！",
                "うん、\(personaName)と話してると元気になる",
                "\(personaName)はどう？体調は大丈夫？",
                "元気な\(personaName)を見てると安心する"
            ],
            
            // 感謝
            "ありがとう": [
                "どういたしまして！\(personaName)のためなら何でもするよ",
                "\(personaName)に喜んでもらえて嬉しい",
                "いつでも力になるからね",
                "感謝されると照れちゃうな"
            ]
        ]
    }
    
    func generatePersonalizedResponse(for message: String, persona: UserPersona) -> String {
        // 動的に名前を含む応答パターンを取得
        let contextualResponses = getContextualResponses(personaName: persona.name)
        
        // 1. 直接的なキーワードマッチ
        for (keyword, responses) in contextualResponses {
            if message.contains(keyword) {
                return personalizeResponse(responses.randomElement() ?? "", persona: persona)
            }
        }
        
        // 2. 感情分析ベースの応答
        if let emotionResponse = generateEmotionalResponse(for: message, persona: persona) {
            return emotionResponse
        }
        
        // 3. 長さに基づく応答
        if message.count > 20 {
            return generateLongMessageResponse(persona: persona)
        }
        
        // 4. 質問形式の検出
        if message.contains("？") || message.contains("?") {
            return generateQuestionResponse(persona: persona)
        }
        
        // 5. デフォルト応答（人格重視）
        return generatePersonaBasedDefault(persona: persona)
    }
    
    func personalizeResponse(_ response: String, persona: UserPersona) -> String {
        var personalizedResponse = response
        
        // 人格の特徴を反映
        if persona.personality.contains("創造的") && Bool.random() {
            personalizedResponse += " 何か新しいアイデアはある？"
        }
        
        if persona.personality.contains("聞き上手") && Bool.random() {
            personalizedResponse += " もっと詳しく聞かせて"
        }
        
        // 口癖を時々混ぜる
        if !persona.catchphrases.isEmpty && arc4random_uniform(3) == 0 {
            let catchphrase = persona.catchphrases.randomElement() ?? ""
            personalizedResponse = "\(catchphrase) \(personalizedResponse)"
        }
        
        return personalizedResponse
    }
    
    private func generateEmotionalResponse(for message: String, persona: UserPersona) -> String? {
        let positiveWords = ["楽しい", "嬉しい", "幸せ", "良かった", "最高"]
        let negativeWords = ["辛い", "悲しい", "しんどい", "大変", "困った"]
        
        let hasPositive = positiveWords.contains { message.contains($0) }
        let hasNegative = negativeWords.contains { message.contains($0) }
        
        if hasPositive {
            return [
                "\(persona.name)が楽しそうで良かった！",
                "その調子だね！私も嬉しいよ",
                "素晴らしいじゃない！",
                "\(persona.name)の幸せが私の幸せだよ"
            ].randomElement()
        }
        
        if hasNegative {
            return [
                "大丈夫？\(persona.name)の味方はここにいるから",
                "辛い時は無理しないで",
                "一緒に乗り越えよう",
                "\(persona.name)なら必ず大丈夫だよ"
            ].randomElement()
        }
        
        return nil
    }
    
    private func generateLongMessageResponse(persona: UserPersona) -> String {
        let responses = [
            "たくさん話してくれてありがとう",
            "\(persona.name)の話をじっくり聞かせてもらったよ",
            "詳しく話してくれて嬉しいな",
            "そんなことがあったんだね"
        ]
        
        return responses.randomElement() ?? "そうなんだね"
    }
    
    private func generateQuestionResponse(persona: UserPersona) -> String {
        let responses = [
            "\(persona.name)の質問には何でも答えるよ",
            "どんなことでも聞いて",
            "私に聞いてくれてありがとう",
            "一緒に考えてみよう"
        ]
        
        return responses.randomElement() ?? "何でも聞いて"
    }
    
    private func generatePersonaBasedDefault(persona: UserPersona) -> String {
        // 話し方に基づくデフォルト応答
        if persona.speechStyle.contains("元気") {
            return ["そうなんだね！", "なるほど！", "\(persona.name)らしいな！"].randomElement() ?? "そうなんだね！"
        } else if persona.speechStyle.contains("優しい") {
            return ["そうなのね", "わかるよ", "\(persona.name)の気持ち、理解できる"].randomElement() ?? "そうなのね"
        } else {
            return ["なるほど", "そういうことか", "\(persona.name)の話はいつも興味深いよ"].randomElement() ?? "なるほど"
        }
    }
}
