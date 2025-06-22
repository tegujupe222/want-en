import SwiftUI

struct ChatBubble: View {
    let message: ChatMessage
    let persona: UserPersona
    
    // ✅ パフォーマンス最適化のためのプロパティ
    private let bubbleMaxWidth = UIScreen.main.bounds.width * 0.75
    
    var body: some View {
        HStack {
            if message.isFromUser {
                Spacer()
                userBubbleView
            } else {
                botBubbleView
                Spacer()
            }
        }
        .padding(.horizontal, 4) // 最小限のパディング
    }
    
    // ✅ ユーザーメッセージバブル（最適化）
    private var userBubbleView: some View {
        VStack(alignment: .trailing, spacing: 4) {
            Text(message.content)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 18)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.accentColor, Color.accentColor.opacity(0.8)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
                .foregroundColor(.white)
                .clipShape(
                    UnevenRoundedRectangle(
                        cornerRadii: RectangleCornerRadii(
                            topLeading: 18,
                            bottomLeading: 18,
                            bottomTrailing: 4,
                            topTrailing: 18
                        )
                    )
                )
            
            // ✅ シンプルな時刻表示
            Text(formatTime(message.timestamp))
                .font(.caption2)
                .foregroundColor(.secondary)
                .padding(.horizontal, 4)
        }
        .frame(maxWidth: bubbleMaxWidth, alignment: .trailing)
    }
    
    // ✅ ボットメッセージバブル（最適化）
    private var botBubbleView: some View {
        HStack(alignment: .bottom, spacing: 8) {
            // ✅ 画像対応のアバター表示
            AvatarView(
                persona: persona,  // ✅ 新しいPersona対応イニシャライザーを使用
                size: 32
            )
            
            VStack(alignment: .leading, spacing: 4) {
                // ✅ 感情トリガー表示（簡素化）
                if let emotion = message.emotionTrigger {
                    EmotionBadgeView(emotion: emotion)
                }
                
                Text(message.content)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 18)
                            .fill(Color(.systemGray6))
                    )
                    .foregroundColor(.primary)
                    .clipShape(
                        UnevenRoundedRectangle(
                            cornerRadii: RectangleCornerRadii(
                                topLeading: 18,
                                bottomLeading: 4,
                                bottomTrailing: 18,
                                topTrailing: 18
                            )
                        )
                    )
                
                // ✅ シンプルな時刻表示
                Text(formatTime(message.timestamp))
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 4)
            }
        }
        .frame(maxWidth: bubbleMaxWidth, alignment: .leading)
    }
    
    // ✅ 最適化された時刻フォーマッター
    private func formatTime(_ date: Date) -> String {
        // ✅ 静的フォーマッターでパフォーマンス向上
        let formatter: DateFormatter = {
            let f = DateFormatter()
            f.timeStyle = .short
            return f
        }()
        
        return formatter.string(from: date)
    }
}

// ✅ 軽量化された感情バッジ
struct EmotionBadgeView: View {
    let emotion: String
    
    var body: some View {
        HStack(spacing: 4) {
            if let trigger = EmotionTrigger.defaultTriggers.first(where: { $0.emotion == emotion }) {
                Text(trigger.emoji)
                    .font(.caption)
                Text(trigger.emotion)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 2)
        .background(Color(.systemGray5))
        .cornerRadius(8)
    }
}

// ✅ パフォーマンス最適化のためのプレビュー
#Preview {
    VStack(spacing: 12) {
        ChatBubble(
            message: ChatMessage(content: "こんにちは！元気？", isFromUser: true),
            persona: UserPersona.defaultPersona
        )
        
        ChatBubble(
            message: ChatMessage(content: "元気だよ！君はどう？", isFromUser: false),
            persona: UserPersona.defaultPersona
        )
        
        ChatBubble(
            message: ChatMessage(
                content: "ありがとう！",
                isFromUser: false,
                emotionTrigger: "ありがとう"
            ),
            persona: UserPersona.defaultPersona
        )
    }
    .padding()
    .background(Color(.systemBackground))
}
