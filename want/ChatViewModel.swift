import Foundation
import SwiftUI

@MainActor
class ChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var isLoading = false
    @Published var selectedPersona: UserPersona?
    @Published var currentMessage = ""
    
    // ✅ 安定性のための追加プロパティ
    @Published var isTyping = false
    @Published var showSubscriptionAlert = false
    @Published var subscriptionAlertMessage = ""
    
    private var isSending = false
    private var sendingTask: Task<Void, Never>?
    
    private let aiChatService: AIChatService
    private let localResponseService: LocalResponseService
    private let subscriptionManager = SubscriptionManager.shared
    
    // ✅ シンプル化されたメッセージ管理
    private var personaMessages: [String: [ChatMessage]] = [:]
    private let messagesKeyPrefix = "chat_messages_"
    private let maxMessagesInMemory = 100
    
    init() {
        self.aiChatService = AIChatService()
        self.localResponseService = LocalResponseService()
        print("🔄 ChatViewModel初期化完了")
    }
    
    deinit {
        sendingTask?.cancel()
        print("♻️ ChatViewModel解放")
    }
    
    // MARK: - ✅ 安定化されたメッセージ送信
    
    func sendMessage() {
        let textToSend = currentMessage.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // ✅ 即座にUI更新（重複送信防止）
        guard !textToSend.isEmpty, !isSending else { return }
        
        // ✅ 即座にテキストフィールドをクリア
        currentMessage = ""
        
        // ✅ 送信処理を開始
        performSendMessage(textToSend)
    }
    
    private func performSendMessage(_ text: String) {
        // ✅ 重複防止フラグ
        isSending = true
        
        // ✅ ペルソナ取得
        let persona: UserPersona
        if let selected = selectedPersona {
            persona = selected
        } else {
            persona = PersonaLoader.shared.safeCurrentPersona
            selectedPersona = persona
        }
        
        print("📤 メッセージ送信開始: \(text)")
        
        // ✅ 1. ユーザーメッセージを即座に表示
        let userMessage = ChatMessage(
            content: text,
            isFromUser: true,
            timestamp: Date()
        )
        
        // ✅ UI を安定して更新
        withAnimation(.easeOut(duration: 0.2)) {
            messages.append(userMessage)
        }
        
        // ✅ 2. AI応答を非同期で処理
        sendingTask?.cancel()
        sendingTask = Task { @MainActor in
            await generateAIResponse(for: text, persona: persona)
        }
    }
    
    private func generateAIResponse(for text: String, persona: UserPersona) async {
        do {
            // ✅ タイピング表示開始
            isTyping = true
            
            // ✅ 少し遅延を入れて自然な感じに
            try await Task.sleep(nanoseconds: 800_000_000) // 0.8秒
            
            print("🤖 AI応答生成中...")
            
            // ✅ AI応答生成
            let response = try await generateResponse(for: text, persona: persona)
            
            // ✅ タイピング表示終了
            isTyping = false
            
            // ✅ 少し遅延してからメッセージ表示
            try await Task.sleep(nanoseconds: 200_000_000) // 0.2秒
            
            // ✅ AI応答メッセージを表示
            let aiMessage = ChatMessage(
                content: response,
                isFromUser: false,
                timestamp: Date()
            )
            
            withAnimation(.easeOut(duration: 0.3)) {
                messages.append(aiMessage)
            }
            
            print("✅ メッセージ送信完了")
            
        } catch {
            // ✅ エラー処理
            isTyping = false
            
            // サブスクリプションエラーの場合
            if let aiError = error as? AIChatError {
                switch aiError {
                case .subscriptionRequired:
                    subscriptionAlertMessage = "AI機能を使用するにはサブスクリプションが必要です。\n設定画面からサブスクリプションを開始してください。"
                    showSubscriptionAlert = true
                    
                    let errorMessage = ChatMessage(
                        content: "AI機能を使用するにはサブスクリプションが必要です。",
                        isFromUser: false,
                        timestamp: Date()
                    )
                    
                    withAnimation(.easeOut(duration: 0.3)) {
                        messages.append(errorMessage)
                    }
                default:
                    let errorMessage = ChatMessage(
                        content: "申し訳ありません。応答の生成に失敗しました。",
                        isFromUser: false,
                        timestamp: Date()
                    )
                    
                    withAnimation(.easeOut(duration: 0.3)) {
                        messages.append(errorMessage)
                    }
                }
            } else {
                let errorMessage = ChatMessage(
                    content: "申し訳ありません。応答の生成に失敗しました。",
                    isFromUser: false,
                    timestamp: Date()
                )
                
                withAnimation(.easeOut(duration: 0.3)) {
                    messages.append(errorMessage)
                }
            }
            
            print("❌ 送信エラー: \(error)")
        }
        
        // ✅ 送信完了フラグをリセット
        isSending = false
        
        // ✅ メッセージを保存（バックグラウンド）
        Task.detached(priority: .background) {
            await self.saveMessages(for: persona)
        }
    }
    
    // MARK: - ✅ シンプル化された応答生成
    
    private func generateResponse(for userMessage: String, persona: UserPersona) async throws -> String {
        let config = AIConfigManager.shared.currentConfig
        
        guard config.isAIEnabled else {
            throw AIChatError.aiNotEnabled
        }
        
        // サブスクリプション状態をチェック
        let subscriptionManager = SubscriptionManager.shared
        guard subscriptionManager.canUseAI() else {
            throw AIChatError.subscriptionRequired
        }
        
        return try await aiChatService.generateResponse(
            persona: persona,
            conversationHistory: messages,
            userMessage: userMessage,
            emotionContext: nil
        )
    }
    
    // MARK: - ✅ シンプルな状態管理
    
    func loadConversation(for persona: UserPersona) {
        print("💬 ペルソナ会話読み込み: \(persona.name)")
        
        selectedPersona = persona
        let loadedMessages = loadMessages(for: persona)
        messages = loadedMessages
        
        print("✅ 会話読み込み完了: \(messages.count) 件のメッセージ")
    }
    
    func loadAIConversation() {
        print("🤖 AI会話モード開始")
        let currentPersona = PersonaLoader.shared.safeCurrentPersona
        selectedPersona = currentPersona
        let loadedMessages = loadMessages(for: currentPersona)
        messages = loadedMessages
    }
    
    func switchToPersona(_ persona: UserPersona) {
        print("🔄 ペルソナ切り替え: \(selectedPersona?.name ?? "なし") → \(persona.name)")
        
        // ✅ 送信中なら停止
        if isSending {
            sendingTask?.cancel()
            isSending = false
            isTyping = false
        }
        
        // ✅ 現在のペルソナ保存
        if let currentPersona = selectedPersona {
            Task.detached(priority: .background) {
                await self.saveMessages(for: currentPersona)
            }
        }
        
        // ✅ 新ペルソナ読み込み
        selectedPersona = persona
        let loadedMessages = loadMessages(for: persona)
        messages = loadedMessages
    }
    
    func clearConversation() {
        guard let persona = selectedPersona else { return }
        
        messages.removeAll()
        personaMessages[persona.name] = []
        
        // UserDefaultsからも削除
        let key = messagesKeyPrefix + persona.name
        UserDefaults.standard.removeObject(forKey: key)
        
        print("🗑️ 会話をクリアしました")
    }
    
    // MARK: - ✅ ユーティリティメソッド
    
    var canSendMessage: Bool {
        return !isSending && !currentMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    func getMessageCount(for persona: UserPersona) -> Int {
        if let cachedMessages = personaMessages[persona.name] {
            return cachedMessages.count
        }
        
        let key = messagesKeyPrefix + persona.name
        guard let data = UserDefaults.standard.data(forKey: key),
              let messages = try? JSONDecoder().decode([ChatMessage].self, from: data) else {
            return 0
        }
        
        return messages.count
    }
    
    func getLastMessage(for persona: UserPersona) -> ChatMessage? {
        if let cachedMessages = personaMessages[persona.name] {
            return cachedMessages.last
        }
        
        let key = messagesKeyPrefix + persona.name
        guard let data = UserDefaults.standard.data(forKey: key),
              let messages = try? JSONDecoder().decode([ChatMessage].self, from: data) else {
            return nil
        }
        
        return messages.last
    }
    
    // MARK: - ✅ プライベートメソッド
    
    private func getMessagesKey(for persona: UserPersona) -> String {
        return "\(messagesKeyPrefix)\(persona.name)"
    }
    
    private func saveMessages(for persona: UserPersona) async {
        let key = messagesKeyPrefix + persona.name
        personaMessages[persona.name] = messages
        
        do {
            let data = try JSONEncoder().encode(messages)
            UserDefaults.standard.set(data, forKey: key)
            print("💾 メッセージ保存完了: \(messages.count) 件")
        } catch {
            print("❌ メッセージ保存エラー: \(error)")
        }
    }
    
    private func loadMessages(for persona: UserPersona) -> [ChatMessage] {
        let key = messagesKeyPrefix + persona.name
        
        // メモリから読み込み
        if let cachedMessages = personaMessages[persona.name] {
            return cachedMessages
        }
        
        // UserDefaultsから読み込み
        guard let data = UserDefaults.standard.data(forKey: key),
              let messages = try? JSONDecoder().decode([ChatMessage].self, from: data) else {
            return []
        }
        
        // メモリにキャッシュ
        personaMessages[persona.name] = messages
        
        return messages
    }
    
    private func createInitialMessage(for persona: UserPersona) {
        let welcomeContent = generateWelcomeMessage(for: persona)
        let welcomeMessage = ChatMessage(
            content: welcomeContent,
            isFromUser: false,
            timestamp: Date()
        )
        
        messages = [welcomeMessage]
        personaMessages[persona.name] = messages
        
        Task.detached(priority: .background) {
            await self.saveMessages(for: persona)
        }
        
        print("🆕 初期メッセージ作成完了")
    }
    
    private func generateWelcomeMessage(for persona: UserPersona) -> String {
        let relationship = persona.relationship.lowercased()
        let name = persona.name
        
        switch relationship {
        case let r where r.contains("家族") || r.contains("母") || r.contains("父"):
            return "こんにちは！\(name)よ。元気にしてた？何か話したいことはある？"
        case let r where r.contains("友"):
            return "やあ！久しぶり〜！最近どう？何か面白いことあった？"
        case let r where r.contains("恋人"):
            return "おかえり♪ 今日はどんな一日だった？聞かせて！"
        case let r where r.contains("先生"):
            return "こんにちは。今日も一日お疲れさまでした。何かお話ししたいことはありますか？"
        default:
            let catchphrase = persona.catchphrases.first ?? ""
            if catchphrase.isEmpty {
                return "こんにちは！\(name)です。今日はよろしくお願いします！"
            } else {
                return "\(catchphrase) こんにちは！\(name)です。お話ししましょう！"
            }
        }
    }
    
    func saveOnAppWillTerminate() {
        sendingTask?.cancel()
        if let persona = selectedPersona {
            Task.detached(priority: .high) {
                await self.saveMessages(for: persona)
                UserDefaults.standard.synchronize()
            }
        }
        print("✅ アプリ終了時保存完了")
    }
    
    func printDebugInfo() {
        print("📊 ChatViewModel デバッグ情報:")
        print("  - 選択ペルソナ: \(selectedPersona?.name ?? "なし")")
        print("  - メッセージ数: \(messages.count)")
        print("  - 送信中: \(isSending)")
        print("  - タイピング中: \(isTyping)")
        print("  - サブスクリプション: \(subscriptionManager.subscriptionStatus.displayName)")
    }
}

// MARK: - Error Types

enum ChatError: LocalizedError {
    case aiNotEnabled
    case invalidPersona
    case networkError
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .aiNotEnabled:
            return "AI機能が有効になっていません"
        case .invalidPersona:
            return "無効なペルソナです"
        case .networkError:
            return "ネットワークエラーが発生しました"
        case .unknown:
            return "不明なエラーが発生しました"
        }
    }
}
