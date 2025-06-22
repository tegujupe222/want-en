import SwiftUI
import PhotosUI

// MARK: - Modern Image Picker (iOS 16+)
@available(iOS 16.0, *)
struct ModernImagePicker: View {
    @Binding var selectedImage: UIImage?
    @State private var selectedPhotoItem: PhotosPickerItem?
    
    let onImageSelected: (UIImage) -> Void
    
    var body: some View {
        PhotosPicker(
            selection: $selectedPhotoItem,
            matching: .images
        ) {
            ImagePickerButton()
        }
        .onChange(of: selectedPhotoItem) { oldValue, newValue in
            Task {
                if let newValue = newValue,
                   let data = try? await newValue.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    await MainActor.run {
                        selectedImage = image
                        onImageSelected(image)
                    }
                }
            }
        }
    }
}

// MARK: - Legacy Image Picker (iOS 15 and below)
struct LegacyImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Environment(\.presentationMode) var presentationMode
    
    let onImageSelected: (UIImage) -> Void
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        picker.allowsEditing = true
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: LegacyImagePicker
        
        init(_ parent: LegacyImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let editedImage = info[.editedImage] as? UIImage {
                parent.selectedImage = editedImage
                parent.onImageSelected(editedImage)
            } else if let originalImage = info[.originalImage] as? UIImage {
                parent.selectedImage = originalImage
                parent.onImageSelected(originalImage)
            }
            
            parent.presentationMode.wrappedValue.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}

// MARK: - Universal Image Picker
struct UniversalImagePicker: View {
    @Binding var selectedImage: UIImage?
    @State private var showingLegacyPicker = false
    
    let onImageSelected: (UIImage) -> Void
    
    var body: some View {
        Group {
            if #available(iOS 16.0, *) {
                ModernImagePicker(
                    selectedImage: $selectedImage,
                    onImageSelected: onImageSelected
                )
            } else {
                Button(action: {
                    showingLegacyPicker = true
                }) {
                    ImagePickerButton()
                }
                .sheet(isPresented: $showingLegacyPicker) {
                    LegacyImagePicker(
                        selectedImage: $selectedImage,
                        onImageSelected: onImageSelected
                    )
                }
            }
        }
    }
}

// MARK: - Image Picker Button
struct ImagePickerButton: View {
    var body: some View {
        HStack {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.title2)
                .foregroundColor(.blue)
            
            Text("写真を選択")
                .font(.body)
                .foregroundColor(.blue)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(Color.blue.opacity(0.1))
        .cornerRadius(8)
    }
}

// MARK: - Avatar Image Preview
struct AvatarImagePreview: View {
    let image: UIImage?
    let size: CGFloat
    let backgroundColor: Color
    
    init(image: UIImage?, size: CGFloat = 100, backgroundColor: Color = .gray.opacity(0.2)) {
        self.image = image
        self.size = size
        self.backgroundColor = backgroundColor
    }
    
    var body: some View {
        ZStack {
            Circle()
                .fill(backgroundColor)
                .frame(width: size, height: size)
            
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: size, height: size)
                    .clipShape(Circle())
            } else {
                Image(systemName: "person.crop.circle")
                    .font(.system(size: size * 0.5))
                    .foregroundColor(.gray)
            }
        }
    }
}

// MARK: - Image Options View
struct ImageOptionsView: View {
    @Binding var selectedImage: UIImage?
    @Binding var avatarEmoji: String
    @Binding var showingImagePicker: Bool
    
    let onImageSelected: (UIImage) -> Void
    let onEmojiSelected: () -> Void
    let onRemoveImage: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Text("アバター設定")
                .font(.headline)
                .fontWeight(.semibold)
            
            HStack(spacing: 20) {
                // 現在のアバタープレビュー
                VStack(spacing: 8) {
                    if let image = selectedImage {
                        AvatarImagePreview(image: image, size: 80)
                    } else if !avatarEmoji.isEmpty {
                        ZStack {
                            Circle()
                                .fill(Color.blue.opacity(0.2))
                                .frame(width: 80, height: 80)
                            
                            Text(avatarEmoji)
                                .font(.system(size: 40))
                        }
                    } else {
                        AvatarImagePreview(image: nil, size: 80)
                    }
                    
                    Text("現在のアバター")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                VStack(spacing: 12) {
                    // 写真を選択ボタン
                    UniversalImagePicker(
                        selectedImage: $selectedImage,
                        onImageSelected: onImageSelected
                    )
                    
                    // 絵文字に戻すボタン
                    Button(action: onEmojiSelected) {
                        HStack {
                            Image(systemName: "face.smiling")
                            Text("絵文字を使用")
                        }
                        .font(.body)
                        .foregroundColor(.orange)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 16)
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(8)
                    }
                    
                    // 画像を削除ボタン
                    if selectedImage != nil {
                        Button(action: onRemoveImage) {
                            HStack {
                                Image(systemName: "trash")
                                Text("画像を削除")
                            }
                            .font(.body)
                            .foregroundColor(.red)
                            .padding(.vertical, 12)
                            .padding(.horizontal, 16)
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(8)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Preview
struct ImagePickerView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            ImageOptionsView(
                selectedImage: .constant(nil),
                avatarEmoji: .constant("😊"),
                showingImagePicker: .constant(false),
                onImageSelected: { _ in },
                onEmojiSelected: { },
                onRemoveImage: { }
            )
            
            AvatarImagePreview(image: nil, size: 100)
        }
        .padding()
    }
}
