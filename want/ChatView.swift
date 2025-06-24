import SwiftUI

struct ChatView: View {
    @StateObject private var viewModel = ChatViewModel()
    @Environment(\.dismiss) private var dismiss
    
    let isAIMode: Bool
    let selectedPersona: UserPersona?
    
    @State private var showingPersonaSelection = false
    @State private var isInitialized = false
    @State private var initializationAttempts = 0  // ✅ 初期化試行回数を追跡
    @State private var showError = false  // ✅ エラー表示フラグ
    
    init(isAIMode: Bool = false, persona: UserPersona? = nil) {
        self.isAIMode = isAIMode
        self.selectedPersona = persona
        print("🔧 ChatView init - persona: \(persona?.name ?? "nil"), isAIMode: \(isAIMode)")
    }
    
    var body: some View {
        ZStack {
            if isInitialized && viewModel.selectedPersona != nil {
                // ✅ 完全に初期化完了後にメインコンテンツを表示
                mainContent
            } else if showError {
                // ✅ エラー画面
                errorView
            } else {
                // ✅ 初期化中のローディング画面
                loadingView
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            setupChatWithRetry()
        }
        .background(Color(.systemBackground))
        .alert("サブスクリプションが必要です", isPresented: $viewModel.showSubscriptionAlert) {
            Button("設定を開く") {
                // 設定画面を開く処理
                // ここでは簡略化のため、アラートを閉じるだけ
            }
            Button("キャンセル", role: .cancel) {}
        } message: {
            Text(viewModel.subscriptionAlertMessage)
        }
    }
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .stroke(Color(.systemGray).opacity(0.3), lineWidth: 4)
                    .frame(width: 50, height: 50)
                
                Circle()
                    .trim(from: 0, to: 0.7)
                    .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .frame(width: 50, height: 50)
                    .rotationEffect(.degrees(-90))
                    .animation(Animation.linear(duration: 1).repeatForever(autoreverses: false), value: isInitialized)
            }
            
            VStack(spacing: 8) {
                Text("チャットを準備中...")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                if initializationAttempts > 0 {
                    Text("試行回数: \(initializationAttempts + 1)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if let persona = selectedPersona {
                    Text(persona.name)
                        .font(.subheadline)
                        .foregroundColor(.blue)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
    
    // MARK: - Error View
    
    private var errorView: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 50))
                .foregroundColor(.orange)
            
            Text("チャットの読み込みに失敗しました")
                .font(.headline)
                .foregroundColor(.primary)
            
            Text("もう一度お試しください")
                .font(.body)
                .foregroundColor(.secondary)
            
            Button("再試行") {
                retryInitialization()
            }
            .buttonStyle(.borderedProminent)
            
            Button("戻る") {
                dismiss()
            }
            .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
    
    // MARK: - Main Content
    
    private var mainContent: some View {
        GeometryReader { geometry in
        VStack(spacing: 0) {
            // ヘッダー
            headerView
            
            // メッセージリスト
            messagesScrollView
                    .frame(maxWidth: geometry.size.width > 768 ? 600 : nil) // iPadで最大幅を制限
                    .frame(maxWidth: .infinity)
            
            // 入力エリア
            messageInputView
                    .frame(maxWidth: geometry.size.width > 768 ? 600 : nil) // iPadで最大幅を制限
                    .frame(maxWidth: .infinity)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
    
    // MARK: - Header View
    
    private var headerView: some View {
        HStack {
            // 戻るボタン
            Button(action: {
                print("🔙 チャット画面から戻る")
                dismiss()
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                        .font(.title2)
                        .fontWeight(.medium)
                    Text("戻る")
                        .font(.body)
                }
                .foregroundColor(.blue)
            }
            
            Spacer()
            
            // タイトル
            VStack(spacing: 2) {
                if let persona = viewModel.selectedPersona {
                    Text(persona.name)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text(persona.relationship)
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    Text("チャット")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
            }
            
            Spacer()
            
            // メニューボタン
            Menu {
                if isAIMode {
                    Button("ペルソナを変更") {
                        showingPersonaSelection = true
                    }
                }
                
                Button("会話をクリア") {
                    viewModel.clearConversation()
                }
                
                Button("デバッグ情報") {
                    viewModel.printDebugInfo()
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .font(.title2)
                    .foregroundColor(.blue)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
        .overlay(
            Rectangle()
                .frame(height: 0.5)
                .foregroundColor(Color(.separator)),
            alignment: .bottom
        )
    }
    
    // MARK: - Messages Scroll View
    
    private var messagesScrollView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 12) {
                    if viewModel.messages.isEmpty {
                        // 空の状態表示
                        VStack(spacing: 16) {
                            Image(systemName: "bubble.left.and.bubble.right")
                                .font(.system(size: 50))
                                .foregroundColor(.gray.opacity(0.5))
                            
                            Text("会話を始めましょう")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            
                            Text("下のメッセージ欄から\n話しかけてみてください")
                                .font(.body)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 50)
                    } else {
                        ForEach(viewModel.messages) { message in
                            MessageBubbleView(
                                message: message,
                                persona: viewModel.selectedPersona ?? UserPersona.defaultPersona
                            )
                            .id(message.id)
                        }
                    }
                    
                    // タイピングインジケーター
                    if viewModel.isTyping {
                        TypingIndicatorView(persona: viewModel.selectedPersona)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
            }
            .onChange(of: viewModel.messages.count) { oldValue, newValue in
                // 新しいメッセージが追加されたら自動スクロール
                if let lastMessage = viewModel.messages.last {
                    withAnimation(.easeOut(duration: 0.3)) {
                        proxy.scrollTo(lastMessage.id, anchor: .bottom)
                    }
                }
            }
        }
    }
    
    // MARK: - Message Input View
    
    private var messageInputView: some View {
        VStack(spacing: 12) {
            // テキスト入力エリア
            HStack(spacing: 12) {
                TextField("メッセージを入力...", text: $viewModel.currentMessage, axis: .vertical)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .lineLimit(1...4)
                    .submitLabel(.send)
                    .onSubmit {
                        if canSendMessage {
                            sendMessage()
                        }
                    }
                    .onChange(of: viewModel.currentMessage) { oldValue, newValue in
                        // 文字数制限
                        if newValue.count > 500 {
                            viewModel.currentMessage = String(newValue.prefix(500))
                        }
                    }
                
                // 送信ボタン
                Button(action: sendMessage) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title2)
                        .foregroundColor(canSendMessage ? .blue : .gray)
                }
                .disabled(!canSendMessage)
            }
        }
        .padding(.horizontal)
        .padding(.bottom, 8)
        .background(Color(.systemBackground))
        .overlay(
            Rectangle()
                .frame(height: 0.5)
                .foregroundColor(Color(.separator)),
            alignment: .top
        )
    }
    
    // MARK: - Computed Properties
    
    private var canSendMessage: Bool {
        return !viewModel.currentMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
               !viewModel.isLoading && isInitialized
    }
    
    // MARK: - Methods
    
    // ✅ リトライ機能付きの初期化
    private func setupChatWithRetry() {
        initializationAttempts += 1
        print("🔄 ChatView初期化開始 (試行: \(initializationAttempts))")
        
        Task { @MainActor in
            do {
                // ✅ 十分な待機時間を確保
                try await Task.sleep(nanoseconds: 500_000_000) // 0.5秒
                
                let personaToUse: UserPersona
                
                if let persona = selectedPersona {
                    print("📋 指定ペルソナを使用: \(persona.name)")
                    personaToUse = persona
                } else if isAIMode {
                    print("🤖 AIモード - デフォルトペルソナを使用")
                    personaToUse = PersonaLoader.shared.safeCurrentPersona
                } else {
                    print("🔧 デフォルトペルソナを使用")
                    personaToUse = PersonaLoader.shared.safeCurrentPersona
                }
                
                // ✅ ペルソナの妥当性を確認
                guard !personaToUse.name.isEmpty else {
                    throw ChatInitializationError.invalidPersona
                }
                
                print("✅ 使用するペルソナ: \(personaToUse.name)")
                
                // ✅ ChatViewModelの読み込み
                viewModel.loadConversation(for: personaToUse)
                
                // ✅ 初期化完了の確認
                try await Task.sleep(nanoseconds: 300_000_000) // 0.3秒
                
                guard viewModel.selectedPersona != nil else {
                    throw ChatInitializationError.viewModelNotReady
                }
                
                // ✅ 初期化完了
                withAnimation(.easeInOut(duration: 0.3)) {
                    isInitialized = true
                }
                
                print("✅ ChatView初期化完了 - ペルソナ: \(viewModel.selectedPersona?.name ?? "nil")")
                
            } catch {
                print("❌ 初期化エラー (試行 \(initializationAttempts)): \(error)")
                
                if initializationAttempts < 3 {
                    // ✅ 最大3回まで再試行
                    try? await Task.sleep(nanoseconds: 1_000_000_000) // 1秒待機
                    setupChatWithRetry()
                } else {
                    // ✅ 3回失敗したらエラー画面を表示
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showError = true
                    }
                }
            }
        }
    }
    
    private func retryInitialization() {
        showError = false
        isInitialized = false
        initializationAttempts = 0
        setupChatWithRetry()
    }
    
    private func sendMessage() {
        guard canSendMessage else { return }
        
        print("📤 メッセージ送信: \(viewModel.currentMessage)")
        
        // キーボードを隠す
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        
        // メッセージ送信
        viewModel.sendMessage()
    }
}

// MARK: - Supporting Views

struct TypingIndicatorView: View {
    let persona: UserPersona?
    
    var body: some View {
        HStack {
            if let persona = persona {
                AvatarView(persona: persona, size: 32)
            }
            
            VStack(alignment: .leading) {
                HStack(spacing: 4) {
                    ForEach(0..<3) { index in
                        Circle()
                            .fill(Color.secondary)
                            .frame(width: 8, height: 8)
                            .scaleEffect(1.0)
                            .animation(
                                Animation.easeInOut(duration: 0.6)
                                    .repeatForever()
                                    .delay(Double(index) * 0.2),
                                value: UUID()
                            )
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color(.systemGray6))
                .cornerRadius(18)
                
                Text("入力中...")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 4)
            }
            
            Spacer()
        }
        .padding(.horizontal)
    }
}

struct MessageBubbleView: View {
    let message: ChatMessage
    let persona: UserPersona
    
    var body: some View {
        HStack {
            if message.isFromUser {
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(message.content)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(18)
                        .font(.body)
                    
                    Text(formatTime(message.timestamp))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: UIScreen.main.bounds.width * 0.75, alignment: .trailing)
            } else {
                HStack(alignment: .bottom, spacing: 8) {
                    AvatarView(persona: persona, size: 32)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(message.content)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(Color(.systemGray6))
                            .foregroundColor(.primary)
                            .cornerRadius(18)
                            .font(.body)
                        
                        Text(formatTime(message.timestamp))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: UIScreen.main.bounds.width * 0.75, alignment: .leading)
                    
                    Spacer()
                }
            }
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Error Types

enum ChatInitializationError: LocalizedError {
    case invalidPersona
    case viewModelNotReady
    case timeout
    
    var errorDescription: String? {
        switch self {
        case .invalidPersona:
            return "ペルソナの設定に問題があります"
        case .viewModelNotReady:
            return "チャットの準備ができていません"
        case .timeout:
            return "初期化がタイムアウトしました"
        }
    }
}

// MARK: - Preview

struct ChatView_Previews: PreviewProvider {
    static var previews: some View {
        ChatView(isAIMode: true, persona: UserPersona.defaultPersona)
    }
}
