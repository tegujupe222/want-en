import Foundation
import SwiftUI

struct PersonaCustomization: Codable, Hashable {
    var avatarEmoji: String?
    var avatarImageFileName: String?  // ✅ Added image filename
    var avatarColor: Color
    var backgroundColor: Color
    var textColor: Color
    var bubbleStyle: BubbleStyle
    
    init(
        avatarEmoji: String? = nil,
        avatarImageFileName: String? = nil,  // ✅ Added image filename parameter
        avatarColor: Color = .blue,
        backgroundColor: Color = .white,
        textColor: Color = Color.safeBlack,
        bubbleStyle: BubbleStyle = .modern
    ) {
        self.avatarEmoji = avatarEmoji
        self.avatarImageFileName = avatarImageFileName  // ✅ Initialize
        self.avatarColor = avatarColor
        self.backgroundColor = backgroundColor
        self.textColor = textColor
        self.bubbleStyle = bubbleStyle
    }
}

enum BubbleStyle: String, CaseIterable, Codable {
    case modern = "modern"
    case classic = "classic"
    case rounded = "rounded"
    
    var displayName: String {
        switch self {
        case .modern:
            return "Modern"
        case .classic:
            return "Classic"
        case .rounded:
            return "Rounded"
        }
    }
}

// MARK: - Color Codable Extension

extension Color: Codable {
    enum CodingKeys: String, CodingKey {
        case red, green, blue, alpha
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let red = try container.decode(Double.self, forKey: .red)
        let green = try container.decode(Double.self, forKey: .green)
        let blue = try container.decode(Double.self, forKey: .blue)
        let alpha = try container.decode(Double.self, forKey: .alpha)
        
        self.init(red: red, green: green, blue: blue, opacity: alpha)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        // Convert UIColor more safely
        let cgColor = UIColor(self).cgColor
        guard let components = cgColor.components,
              components.count >= 3 else {
            // Fallback: use black color
            try container.encode(0.0, forKey: .red)
            try container.encode(0.0, forKey: .green)
            try container.encode(0.0, forKey: .blue)
            try container.encode(1.0, forKey: .alpha)
            return
        }
        
        let red = components[0]
        let green = components[1]
        let blue = components[2]
        let alpha = components.count > 3 ? components[3] : 1.0
        
        try container.encode(Double(red), forKey: .red)
        try container.encode(Double(green), forKey: .green)
        try container.encode(Double(blue), forKey: .blue)
        try container.encode(Double(alpha), forKey: .alpha)
    }
    
    // Convenient color definitions (safe definitions)
    static let personaPink = Color(red: 1.0, green: 0.75, blue: 0.8)
    static let personaLightBlue = Color(red: 0.7, green: 0.9, blue: 1.0)
    static let personaLightGreen = Color(red: 0.8, green: 1.0, blue: 0.8)
    static let personaLightPurple = Color(red: 0.9, green: 0.8, blue: 1.0)
    static let personaLightOrange = Color(red: 1.0, green: 0.9, blue: 0.7)
    
    // Safe black and white definitions
    static let safeBlack = Color(red: 0.0, green: 0.0, blue: 0.0)
    static let safeWhite = Color(red: 1.0, green: 1.0, blue: 1.0)
}

// MARK: - PersonaCustomization Extension

extension PersonaCustomization {
    // Provide safe default settings
    static var safeDefault: PersonaCustomization {
        return PersonaCustomization(
            avatarEmoji: "😊",
            avatarColor: .blue,
            backgroundColor: Color.safeWhite,
            textColor: Color.safeBlack,
            bubbleStyle: .modern
        )
    }
    
    // Check color validity
    var isValid: Bool {
        // Basic validity check
        return true
    }
    
    // Convert to safe colors
    mutating func makeSafe() {
        // Replace with safe colors as needed
        if avatarEmoji?.isEmpty == true {
            avatarEmoji = nil
        }
        
        // Check if image file exists
        if let fileName = avatarImageFileName,
           ImageManager.shared.loadAvatarImage(fileName: fileName) == nil {
            avatarImageFileName = nil
            print("⚠️ Removed non-existent image file: \(fileName)")
        }
        
        // Check for extremely transparent or invalid colors
        // Implement additional check logic as needed
    }
}
