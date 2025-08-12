import Foundation
import SwiftUI
import PhotosUI

class ImageManager: ObservableObject {
    static let shared = ImageManager()
    
    private let documentsDirectory: URL
    private let avatarImagesDirectory: URL
    
    private init() {
        documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        avatarImagesDirectory = documentsDirectory.appendingPathComponent("AvatarImages")
        
        // アバター画像ディレクトリを作成
        createAvatarImagesDirectoryIfNeeded()
    }
    
    // MARK: - Directory Management
    
    private func createAvatarImagesDirectoryIfNeeded() {
        if !FileManager.default.fileExists(atPath: avatarImagesDirectory.path) {
            do {
                try FileManager.default.createDirectory(at: avatarImagesDirectory, withIntermediateDirectories: true)
                print("📁 Created avatar images directory: \(avatarImagesDirectory.path)")
            } catch {
                print("❌ Directory creation error: \(error)")
            }
        }
    }
    
    // MARK: - Image Saving
    
    func saveAvatarImage(_ image: UIImage, for personaId: String) -> String? {
        let fileName = "avatar_\(personaId).jpg"
        let fileURL = avatarImagesDirectory.appendingPathComponent(fileName)
        
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            print("❌ Failed to convert image data")
            return nil
        }
        
        do {
            try imageData.write(to: fileURL)
            print("💾 Saved avatar image: \(fileName)")
            return fileName
        } catch {
            print("❌ Image save error: \(error)")
            return nil
        }
    }
    
    // MARK: - Image Loading
    
    func loadAvatarImage(fileName: String) -> UIImage? {
        let fileURL = avatarImagesDirectory.appendingPathComponent(fileName)
        
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            print("⚠️ Image file not found: \(fileName)")
            return nil
        }
        
        guard let imageData = try? Data(contentsOf: fileURL),
              let image = UIImage(data: imageData) else {
            print("❌ Image load error: \(fileName)")
            return nil
        }
        
        return image
    }
    
    // MARK: - Image Deletion
    
    func deleteAvatarImage(fileName: String) {
        let fileURL = avatarImagesDirectory.appendingPathComponent(fileName)
        
        if FileManager.default.fileExists(atPath: fileURL.path) {
            do {
                try FileManager.default.removeItem(at: fileURL)
                print("🗑️ Deleted avatar image: \(fileName)")
            } catch {
                print("❌ Image deletion error: \(error)")
            }
        }
    }
    
    // MARK: - Utility Methods
    
    func resizeImage(_ image: UIImage, to size: CGSize) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        image.draw(in: CGRect(origin: .zero, size: size))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return resizedImage
    }
    
    func cropImageToCircle(_ image: UIImage) -> UIImage? {
        let size = min(image.size.width, image.size.height)
        let rect = CGRect(x: (image.size.width - size) / 2,
                         y: (image.size.height - size) / 2,
                         width: size,
                         height: size)
        
        guard let cgImage = image.cgImage?.cropping(to: rect) else { return nil }
        
        let croppedImage = UIImage(cgImage: cgImage, scale: image.scale, orientation: image.imageOrientation)
        
        // 円形にクロップ
        UIGraphicsBeginImageContextWithOptions(CGSize(width: size, height: size), false, 0.0)
        let context = UIGraphicsGetCurrentContext()
        context?.addEllipse(in: CGRect(origin: .zero, size: CGSize(width: size, height: size)))
        context?.clip()
        croppedImage.draw(in: CGRect(origin: .zero, size: CGSize(width: size, height: size)))
        let circularImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return circularImage
    }
    
    // MARK: - Cleanup
    
    func cleanupUnusedImages(existingPersonaIds: [String]) {
        do {
            let fileURLs = try FileManager.default.contentsOfDirectory(at: avatarImagesDirectory, includingPropertiesForKeys: nil)
            
            for fileURL in fileURLs {
                let fileName = fileURL.lastPathComponent
                
                // "avatar_" で始まるファイルのみをチェック
                if fileName.hasPrefix("avatar_") {
                    let personaId = String(fileName.dropFirst(7).dropLast(4)) // "avatar_" と ".jpg" を除去
                    
                    if !existingPersonaIds.contains(personaId) {
                        deleteAvatarImage(fileName: fileName)
                        print("🧹 Deleted unused image: \(fileName)")
                    }
                }
            }
        } catch {
            print("❌ Cleanup error: \(error)")
        }
    }
}
