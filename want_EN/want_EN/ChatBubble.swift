import SwiftUI

struct ChatBubble: View {
    let message: ChatMessage
    let persona: UserPersona
    
    // ✅ Performance optimization properties
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
        .padding(.horizontal, 4) // Minimal padding
    }
    
    // ✅ User message bubble (optimized)
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
            
            // ✅ Simple time display
            Text(formatTime(message.timestamp))
                .font(.caption2)
                .foregroundColor(.secondary)
                .padding(.horizontal, 4)
        }
        .frame(maxWidth: bubbleMaxWidth, alignment: .trailing)
    }
    
    // ✅ Bot message bubble (optimized)
    private var botBubbleView: some View {
        HStack(alignment: .bottom, spacing: 8) {
            // ✅ Image-supported avatar display
            AvatarView(
                persona: persona,  // ✅ Using new Persona-compatible initializer
                size: 32
            )
            
            VStack(alignment: .leading, spacing: 4) {
                // ✅ Emotion trigger display (simplified)
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
                
                // ✅ Simple time display
                Text(formatTime(message.timestamp))
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 4)
            }
        }
        .frame(maxWidth: bubbleMaxWidth, alignment: .leading)
    }
    
    // ✅ Optimized time formatter
    private func formatTime(_ date: Date) -> String {
        // ✅ Static formatter for performance improvement
        let formatter: DateFormatter = {
            let f = DateFormatter()
            f.timeStyle = .short
            return f
        }()
        
        return formatter.string(from: date)
    }
}

// ✅ Lightweight emotion badge
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

// ✅ Performance optimized preview
#Preview {
    VStack(spacing: 12) {
        ChatBubble(
            message: ChatMessage(content: "Hello! How are you?", isFromUser: true),
            persona: UserPersona.defaultPersona
        )
        
        ChatBubble(
            message: ChatMessage(content: "I'm doing great! How about you?", isFromUser: false),
            persona: UserPersona.defaultPersona
        )
        
        ChatBubble(
            message: ChatMessage(
                content: "Thank you!",
                isFromUser: false,
                emotionTrigger: "thank you"
            ),
            persona: UserPersona.defaultPersona
        )
    }
    .padding()
    .background(Color(.systemBackground))
}
