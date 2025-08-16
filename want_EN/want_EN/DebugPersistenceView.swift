import SwiftUI

struct DebugPersistenceView: View {
    @StateObject private var chatViewModel = ChatViewModel()
    @State private var testMessage = ""
    @State private var logMessages: [String] = []
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Text("Persistence Debug Test")
                    .font(.title)
                    .fontWeight(.bold)
                
                // 現状表示
                VStack(alignment: .leading, spacing: 8) {
                    Text("Current message count: \(chatViewModel.messages.count)")
                        .font(.headline)
                    
                    Text("Memory usage:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    // ✅ 修正: シンプルなメモリ情報表示
                    Text("Messages: \(chatViewModel.messages.count) items")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 4) {
                            ForEach(Array(chatViewModel.messages.enumerated()), id: \.offset) { index, message in
                                Text("\(index + 1). \(message.isFromUser ? "👤" : "🤖") \(message.content)")
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 2)
                                    .background(message.isFromUser ? Color.blue.opacity(0.1) : Color.gray.opacity(0.1))
                                    .cornerRadius(4)
                            }
                        }
                    }
                    .frame(maxHeight: 200)
                    .border(Color.gray.opacity(0.3))
                }
                
                // テスト用入力
                VStack(spacing: 8) {
                    TextField("Enter test message", text: $testMessage)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    Button("Add Message") {
                        Task { @MainActor in
                            await addTestMessage()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(testMessage.isEmpty)
                }
                
                // テストボタン群
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                    Button("💾 Force Save") {
                        Task { @MainActor in
                            await performForceSave()
                        }
                    }
                    .buttonStyle(.bordered)
                    
                    Button("📱 Force Load") {
                        Task { @MainActor in
                            await performForceLoad()
                        }
                    }
                    .buttonStyle(.bordered)
                    
                    Button("🔍 Debug Info") {
                        Task { @MainActor in
                            chatViewModel.printDebugInfo()
                            addLog("デバッグ情報出力")
                        }
                    }
                    .buttonStyle(.bordered)
                    
                    Button("🗑️ Clear All") {
                        Task { @MainActor in
                            await chatViewModel.clearConversation()
                            addLog("全データクリア")
                        }
                    }
                    .buttonStyle(.bordered)
                    .foregroundColor(.red)
                    
                    Button("🎯 Check UserDefaults") {
                        Task { @MainActor in
                            await checkUserDefaults()
                        }
                    }
                    .buttonStyle(.bordered)
                    
                    Button("🔄 Start AI Chat") {
                        Task { @MainActor in
                            chatViewModel.loadAIConversation()
                            addLog("AI会話開始")
                        }
                    }
                    .buttonStyle(.bordered)
                    
                    Button("📊 Persona Info") {
                        Task { @MainActor in
                            showPersonaInfo()
                        }
                    }
                    .buttonStyle(.bordered)
                    .foregroundColor(.orange)
                }
                
                // ログ表示
                VStack(alignment: .leading, spacing: 4) {
                    Text("Operation Log:")
                        .font(.headline)
                    
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 2) {
                            ForEach(Array(logMessages.enumerated()), id: \.offset) { index, log in
                                Text("\(index + 1). \(log)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .frame(maxHeight: 100)
                    .border(Color.gray.opacity(0.3))
                    
                    Button("Clear Log") {
                        logMessages.removeAll()
                    }
                    .font(.caption)
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Debug")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                Task { @MainActor in
                    addLog("アプリ起動 - メッセージ数: \(chatViewModel.messages.count)")
                    chatViewModel.printDebugInfo()
                }
            }
        }
    }
    
    // MARK: - ✅ 修正版プライベートメソッド
    
    @MainActor
    private func addTestMessage() async {
        guard !testMessage.isEmpty else { return }
        
        // ✅ 修正: currentMessageに設定してからsendMessage()を呼び出し
        let message = "テスト: \(testMessage) (\(Date().formatted(.dateTime.hour().minute().second())))"
        chatViewModel.currentMessage = message
        Task {
            await chatViewModel.sendMessage(message)
        }
        
        addLog("メッセージ追加: \(testMessage)")
        testMessage = ""
    }
    
    @MainActor
    private func performForceSave() async {
        // ✅ 修正: アプリ終了時保存メソッドを使用
        chatViewModel.saveOnAppWillTerminate()
        
        if let persona = chatViewModel.selectedPersona {
            addLog("手動保存実行 - ペルソナ: \(persona.name)")
        } else {
            addLog("強制保存実行（ペルソナ未選択）")
        }
    }
    
    @MainActor
    private func performForceLoad() async {
        // ✅ 修正: 適切な読み込みメソッドを使用
        if let persona = chatViewModel.selectedPersona {
            chatViewModel.switchToPersona(persona)
            addLog("手動読み込み実行 - ペルソナ: \(persona.name)")
        } else {
            chatViewModel.loadAIConversation()
            addLog("AI会話読み込み実行")
        }
    }
    
    @MainActor
    private func showPersonaInfo() {
        if let persona = chatViewModel.selectedPersona {
            addLog("現在のペルソナ: \(persona.name) (\(persona.relationship))")
        } else {
            addLog("ペルソナ未選択")
        }
    }
    
    @MainActor
    private func addLog(_ message: String) {
        let timestamp = Date().formatted(.dateTime.hour().minute().second())
        logMessages.append("[\(timestamp)] \(message)")
        
        // ログが多くなりすぎないよう制限
        if logMessages.count > 20 {
            logMessages.removeFirst()
        }
    }
    
    @MainActor
    private func checkUserDefaults() async {
        // 現在選択されているペルソナのキーを使用
        let key: String
        if let persona = chatViewModel.selectedPersona {
            key = "chat_messages_\(persona.id)"
        } else {
            // デフォルトペルソナのキーを使用
            let defaultPersona = PersonaLoader.shared.safeCurrentPersona
            key = "chat_messages_\(defaultPersona.id)"
        }
        
        await Task.detached {
            if let data = UserDefaults.standard.data(forKey: key) {
                await MainActor.run { [data] in
                    self.addLog("UserDefaults: \(data.count) bytes")
                }
                
                do {
                    let decoder = JSONDecoder()
                    decoder.dateDecodingStrategy = .secondsSince1970
                    let messages = try decoder.decode([ChatMessage].self, from: data)
                    await MainActor.run { [messages] in
                        self.addLog("UserDefaults読み込み成功: \(messages.count)件")
                    }
                } catch {
                    await MainActor.run { [error] in
                        self.addLog("UserDefaults読み込みエラー: \(error.localizedDescription)")
                    }
                }
            } else {
                await MainActor.run {
                    self.addLog("UserDefaults: データなし (キー: \(key))")
                }
            }
        }.value
    }
}

// MARK: - プレビュー

#Preview {
    DebugPersistenceView()
}
