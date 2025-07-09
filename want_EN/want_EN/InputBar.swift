import SwiftUI

struct InputBar: View {
    @Binding var text: String
    let onSend: () -> Void
    @FocusState private var isTextFieldFocused: Bool
    
    // ✅ 安定性のための状態管理
    @State private var isSending = false
    @State private var lastSentText = ""
    
    var body: some View {
        HStack(spacing: 12) {
            // ✅ 安定化されたテキスト入力欄
            TextField("メッセージを入力...", text: $text, axis: .vertical)
                .textFieldStyle(PlainTextFieldStyle())
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color(.systemGray6))
                .cornerRadius(20)
                .focused($isTextFieldFocused)
                .lineLimit(1...4)
                .disabled(isSending)
                // ✅ 最適化された送信処理
                .onSubmit {
                    if canSend {
                        performSend()
                    }
                }
                // ✅ 文字数制限（オプション）
                .onChange(of: text) { oldValue, newValue in
                    if newValue.count > 1000 {
                        text = String(newValue.prefix(1000))
                    }
                }
            
            // ✅ 安定化された送信ボタン
            Button(action: performSend) {
                ZStack {
                    Circle()
                        .fill(buttonColor)
                        .frame(width: 36, height: 36)
                    
                    if isSending {
                        ProgressView()
                            .scaleEffect(0.7)
                            .tint(.white)
                    } else {
                        Image(systemName: "arrow.up")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
            }
            .disabled(!canSend || isSending)
            .animation(.easeInOut(duration: 0.2), value: canSend)
        }
        .padding(.horizontal, 4)
    }
    
    // ✅ 計算プロパティ
    private var canSend: Bool {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmedText.isEmpty && trimmedText != lastSentText && !isSending
    }
    
    private var buttonColor: Color {
        if canSend {
            return Color.blue
        } else {
            return Color(.systemGray4)
        }
    }
    
    // ✅ 安定化された送信処理
    private func performSend() {
        let textToSend = text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // ✅ 重複送信防止
        guard canSend else { return }
        
        // ✅ 送信状態に設定
        isSending = true
        lastSentText = textToSend
        
        // ✅ テキストフィールドを即座にクリア
        text = ""
        
        // ✅ キーボードを隠す
        isTextFieldFocused = false
        
        // ✅ 送信処理実行
        onSend()
        
        // ✅ 短い遅延後に送信状態をリセット
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            isSending = false
        }
        
        // ✅ 重複防止のテキストを一定時間後にクリア
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            lastSentText = ""
        }
    }
    
    private var sendButton: some View {
        Button(action: onSend) {
            Image(systemName: "arrow.up.circle.fill")
                .font(.largeTitle)
                .foregroundColor(canSend ? Color.accentColor : Color(.systemGray))
        }
        .disabled(!canSend)
    }
}

// ✅ パフォーマンステスト用プレビュー
#Preview {
    VStack {
        Spacer()
        
        InputBar(text: .constant("")) {
            print("Send message")
        }
        .padding()
        
        // ✅ テスト用のさまざまな状態
        InputBar(text: .constant("テストメッセージ")) {
            print("Send test message")
        }
        .padding()
    }
    .background(Color(.systemBackground))
}
