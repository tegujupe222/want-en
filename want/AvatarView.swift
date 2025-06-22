import SwiftUI

struct AvatarView: View {
    let name: String
    let emoji: String?
    let imageFileName: String?  // ✅ 画像ファイル名を追加
    let color: Color
    let size: CGFloat
    
    @State private var avatarImage: UIImage?
    
    init(
        name: String,
        emoji: String? = nil,
        imageFileName: String? = nil,  // ✅ 画像ファイル名パラメータを追加
        color: Color = .blue,
        size: CGFloat = 50
    ) {
        self.name = name
        self.emoji = emoji
        self.imageFileName = imageFileName
        self.color = color
        self.size = size
    }
    
    var body: some View {
        Group {
            if let avatarImage = avatarImage {
                // ✅ カスタム画像アバター
                Image(uiImage: avatarImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: size, height: size)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(color.opacity(0.3), lineWidth: 2)
                    )
            } else if let emoji = emoji, !emoji.isEmpty {
                // 絵文字アバター
                ZStack {
                    Circle()
                        .fill(color.opacity(0.2))
                        .frame(width: size, height: size)
                    
                    Text(emoji)
                        .font(.system(size: size * 0.6))
                }
            } else {
                // デフォルトアバター（名前の頭文字）
                Circle()
                    .fill(LinearGradient(
                        gradient: Gradient(colors: [
                            color.opacity(0.7),
                            color.opacity(0.9)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .overlay(
                        Text(String(name.prefix(1)))
                            .font(.system(size: size * 0.4, weight: .semibold))
                            .foregroundColor(.white)
                    )
                    .frame(width: size, height: size)
            }
        }
        .clipShape(Circle())
        .onAppear {
            loadAvatarImage()
        }
        .onChange(of: imageFileName) { oldValue, newValue in
            loadAvatarImage()
        }
    }
    
    private func loadAvatarImage() {
        guard let imageFileName = imageFileName else {
            avatarImage = nil
            return
        }
        
        avatarImage = ImageManager.shared.loadAvatarImage(fileName: imageFileName)
    }
}

// MARK: - Convenience Initializers

extension AvatarView {
    // PersonaCustomizationから直接作成
    init(
        name: String,
        customization: PersonaCustomization,
        size: CGFloat = 50
    ) {
        self.init(
            name: name,
            emoji: customization.avatarEmoji,
            imageFileName: customization.avatarImageFileName,
            color: customization.avatarColor,
            size: size
        )
    }
    
    // UserPersonaから直接作成
    init(
        persona: UserPersona,
        size: CGFloat = 50
    ) {
        self.init(
            name: persona.name,
            emoji: persona.customization.avatarEmoji,
            imageFileName: persona.customization.avatarImageFileName,
            color: persona.customization.avatarColor,
            size: size
        )
    }
}

// MARK: - Avatar Loading States

struct AvatarViewWithLoading: View {
    let name: String
    let customization: PersonaCustomization
    let size: CGFloat
    
    @State private var isLoading = false
    
    var body: some View {
        ZStack {
            AvatarView(
                name: name,
                customization: customization,
                size: size
            )
            .opacity(isLoading ? 0.5 : 1.0)
            
            if isLoading {
                ProgressView()
                    .scaleEffect(0.8)
            }
        }
        .onAppear {
            // 画像読み込み時のローディング状態管理
            if customization.avatarImageFileName != nil {
                isLoading = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    isLoading = false
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        HStack(spacing: 20) {
            AvatarView(
                name: "田中太郎",
                emoji: "😊",
                color: .blue,
                size: 50
            )
            
            AvatarView(
                name: "山田花子",
                emoji: "👩",
                color: .pink,
                size: 50
            )
            
            AvatarView(
                name: "佐藤次郎",
                emoji: nil,
                color: .green,
                size: 50
            )
        }
        
        HStack(spacing: 20) {
            AvatarView(
                name: "アシスタント",
                emoji: "🤖",
                color: .purple,
                size: 40
            )
            
            AvatarView(
                name: "Friend",
                emoji: nil,
                imageFileName: "sample_avatar.jpg",  // ✅ 画像ファイル名の例
                color: .orange,
                size: 60
            )
        }
        
        Text("画像対応アバター")
            .font(.headline)
        
        AvatarViewWithLoading(
            name: "カスタム",
            customization: PersonaCustomization(
                avatarEmoji: nil,
                avatarImageFileName: "custom_avatar.jpg",
                avatarColor: .blue
            ),
            size: 80
        )
    }
    .padding()
}
