import SwiftUI

struct AvatarView: View {
    let name: String
    let emoji: String?
    let imageFileName: String?  // ✅ Added image filename
    let color: Color
    let size: CGFloat
    
    @State private var avatarImage: UIImage?
    
    init(
        name: String,
        emoji: String? = nil,
        imageFileName: String? = nil,  // ✅ Added image filename parameter
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
                // ✅ Custom image avatar
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
                // Emoji avatar
                ZStack {
                    Circle()
                        .fill(color.opacity(0.2))
                        .frame(width: size, height: size)
                    
                    Text(emoji)
                        .font(.system(size: size * 0.6))
                }
            } else {
                // Default avatar (name initials)
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
    // Create directly from PersonaCustomization
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
    
    // Create directly from UserPersona
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
            // Loading state management during image loading
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
                name: "John Smith",
                emoji: "😊",
                color: .blue,
                size: 50
            )
            
            AvatarView(
                name: "Jane Doe",
                emoji: "👩",
                color: .pink,
                size: 50
            )
            
            AvatarView(
                name: "Bob Wilson",
                emoji: nil,
                color: .green,
                size: 50
            )
        }
        
        HStack(spacing: 20) {
            AvatarView(
                name: "Assistant",
                emoji: "🤖",
                color: .purple,
                size: 40
            )
            
            AvatarView(
                name: "Friend",
                emoji: nil,
                imageFileName: "sample_avatar.jpg",  // ✅ Example image filename
                color: .orange,
                size: 60
            )
        }
        
        Text("Image Avatar Support")
            .font(.headline)
        
        AvatarViewWithLoading(
            name: "Custom",
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
