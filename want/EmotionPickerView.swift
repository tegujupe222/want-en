import SwiftUI

struct EmotionPickerView: View {
    let onEmotionSelected: (String) -> Void
    @State private var selectedEmotion: String? = nil
    
    private let emotions = EmotionTrigger.defaultTriggers
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(emotions) { emotion in
                    EmotionButton(
                        emotion: emotion,
                        isSelected: selectedEmotion == emotion.emotion,
                        onTap: {
                            handleEmotionTap(emotion.emotion)
                        }
                    )
                }
            }
            .padding(.horizontal, 4)
        }
    }
    
    private func handleEmotionTap(_ emotion: String) {
        selectedEmotion = emotion
        onEmotionSelected(emotion)
        
        // 選択状態を一定時間後にリセット
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            selectedEmotion = nil
        }
    }
}

struct EmotionButton: View {
    let emotion: EmotionTrigger
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                Text(emotion.emoji)
                    .font(.title2)
                
                Text(emotion.emotion)
                    .font(.caption)
                    .foregroundColor(isSelected ? .white : .secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Group {
                    if isSelected {
                        LinearGradient(
                            gradient: Gradient(colors: [Color.blue, Color.purple]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    } else {
                        Color(.systemGray6)
                    }
                }
            )
            .cornerRadius(12)
            .scaleEffect(isSelected ? 1.1 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: isSelected)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    VStack {
        Spacer()
        
        EmotionPickerView { emotion in
            print("Selected emotion: \(emotion)")
        }
        .padding()
        
        Spacer()
    }
}
