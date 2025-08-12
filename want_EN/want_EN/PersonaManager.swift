import Foundation
import SwiftUI

@MainActor
class PersonaManager: ObservableObject {
    static let shared = PersonaManager()
    
    @Published var personas: [UserPersona] = []
    
    private let userDefaults = UserDefaults.standard
    private let personasKey = "saved_personas"
    
    private init() {
        loadPersonas()
        print("👥 PersonaManager initialization completed")
    }
    
    // MARK: - Public Methods
    
    func addPersona(_ persona: UserPersona) {
        var safePersona = persona
        safePersona.customization.makeSafe()
        
        personas.append(safePersona)
        savePersonas()
        print("➕ Added persona: \(safePersona.name)")
    }
    
    func updatePersona(_ persona: UserPersona) {
        if let index = personas.firstIndex(where: { $0.id == persona.id }) {
            var safePersona = persona
            safePersona.customization.makeSafe()
            
            personas[index] = safePersona
            savePersonas()
            print("🔄 Updated persona: \(safePersona.name)")
            
            // Notify PersonaLoader of update (execute on main actor)
            Task { @MainActor in
                PersonaLoader.shared.refreshCurrentPersona()
            }
        }
    }
    
    func deletePersona(_ persona: UserPersona) {
        personas.removeAll { $0.id == persona.id }
        
        // ✅ Also delete related image files
        if let imageFileName = persona.customization.avatarImageFileName {
            ImageManager.shared.deleteAvatarImage(fileName: imageFileName)
        }
        
        savePersonas()
        print("🗑️ Deleted persona: \(persona.name)")
        
        // Update PersonaLoader if deleted persona was currently selected
        Task { @MainActor in
            if PersonaLoader.shared.currentPersona?.id == persona.id {
                PersonaLoader.shared.setDefaultPersona()
            }
        }
    }
    
    func getPersona(by id: String) -> UserPersona? {
        return personas.first { $0.id == id }
    }
    
    func getAllPersonas() -> [UserPersona] {
        return personas
    }
    
    func getPersonaCount() -> Int {
        return personas.count
    }
    
    // MARK: - Validation Methods
    
    func validatePersona(_ persona: UserPersona) -> Bool {
        // Basic validation check
        guard !persona.name.isEmpty,
              !persona.relationship.isEmpty,
              !persona.personality.isEmpty,
              !persona.speechStyle.isEmpty else {
            return false
        }
        return true
    }
    
    func cleanupInvalidPersonas() {
        let originalCount = personas.count
        personas = personas.filter { validatePersona($0) }
        
        if personas.count != originalCount {
            savePersonas()
            print("🧹 Cleaned up invalid personas: \(originalCount - personas.count) removed")
        }
    }
    
    // MARK: - Private Methods
    
    private func savePersonas() {
        do {
            // Validate before saving
            let validPersonas = personas.compactMap { persona in
                var validPersona = persona
                validPersona.customization.makeSafe()
                return validatePersona(validPersona) ? validPersona : nil
            }
            
            let data = try JSONEncoder().encode(validPersonas)
            userDefaults.set(data, forKey: personasKey)
            print("💾 Personas saved: \(validPersonas.count) items")
        } catch {
            print("❌ Persona save error: \(error.localizedDescription)")
            // Protect existing data on error (do nothing)
        }
    }
    
    private func loadPersonas() {
        guard let data = userDefaults.data(forKey: personasKey) else {
            print("📱 No saved personas - creating default personas")
            createDefaultPersonas()
            return
        }
        
        do {
            let loadedPersonas = try JSONDecoder().decode([UserPersona].self, from: data)
            
            // Validate loaded personas
            personas = loadedPersonas.compactMap { persona in
                var validPersona = persona
                validPersona.customization.makeSafe()
                
                // Validation check
                if validatePersona(validPersona) {
                    return validPersona
                } else {
                    print("⚠️ Skipped invalid persona: \(persona.name)")
                    return nil
                }
            }
            
            // Create defaults if no personas exist
            if personas.isEmpty {
                print("⚠️ No valid personas found, creating defaults")
                createDefaultPersonas()
            } else {
                print("📱 Personas loaded: \(personas.count) items")
            }
            
        } catch {
            print("❌ Persona load error: \(error.localizedDescription)")
            // Create default personas on error
            createDefaultPersonas()
        }
    }
    
    private func createDefaultPersonas() {
        let defaultPersonas = [
            UserPersona(
                name: "Mom",
                relationship: "Family",
                personality: ["Kind", "Worried", "Loving"],
                speechStyle: "Warm and caring tone",
                catchphrases: ["It's okay", "Good job"],
                favoriteTopics: ["Daily events", "Health", "Family matters"],
                mood: .happy,
                customization: PersonaCustomization(
                    avatarEmoji: "👩",
                    avatarColor: Color.personaPink
                )
            ),
            UserPersona(
                name: "Friend",
                relationship: "Best Friend",
                personality: ["Cheerful", "Friendly", "Humorous"],
                speechStyle: "Casual and approachable",
                catchphrases: ["Really?", "That's amazing!"],
                favoriteTopics: ["Hobbies", "Entertainment", "Love"],
                mood: .excited,
                customization: PersonaCustomization(
                    avatarEmoji: "😊",
                    avatarColor: Color.personaLightBlue
                )
            ),
            UserPersona(
                name: "Teacher",
                relationship: "Mentor",
                personality: ["Intelligent", "Kind", "Guiding"],
                speechStyle: "Polite and calm tone",
                catchphrases: ["I see", "That's wonderful"],
                favoriteTopics: ["Learning", "Growth", "Future goals"],
                mood: .calm,
                customization: PersonaCustomization(
                    avatarEmoji: "👨‍🏫",
                    avatarColor: Color.personaLightGreen
                )
            )
        ]
        
        personas = defaultPersonas
        savePersonas()
        print("🆕 Default personas created: \(defaultPersonas.count) items")
    }
    
    // MARK: - Utility Methods
    
    func searchPersonas(by keyword: String) -> [UserPersona] {
        guard !keyword.isEmpty else { return personas }
        
        return personas.filter { persona in
            persona.name.localizedCaseInsensitiveContains(keyword) ||
            persona.relationship.localizedCaseInsensitiveContains(keyword) ||
            persona.personality.contains { $0.localizedCaseInsensitiveContains(keyword) }
        }
    }
    
    func getPersonasByRelationship(_ relationship: String) -> [UserPersona] {
        return personas.filter { $0.relationship == relationship }
    }
    
    func getPersonasByMood(_ mood: PersonaMood) -> [UserPersona] {
        return personas.filter { $0.mood == mood }
    }
    
    // ✅ Cleanup unused images
    func cleanupUnusedImages() {
        let existingPersonaIds = personas.map { $0.id }
        ImageManager.shared.cleanupUnusedImages(existingPersonaIds: existingPersonaIds)
        print("🧹 Unused images cleanup completed")
    }
    
    // MARK: - Export/Import Methods
    
    func exportPersonasData() -> Data? {
        do {
            return try JSONEncoder().encode(personas)
        } catch {
            print("❌ Persona export error: \(error.localizedDescription)")
            return nil
        }
    }
    
    func importPersonasData(_ data: Data) -> Bool {
        do {
            let importedPersonas = try JSONDecoder().decode([UserPersona].self, from: data)
            
            // Validate imported personas
            let validPersonas = importedPersonas.compactMap { persona in
                var validPersona = persona
                validPersona.customization.makeSafe()
                return validatePersona(validPersona) ? validPersona : nil
            }
            
            // Check IDs to avoid duplicates with existing personas
            let existingIds = Set(personas.map { $0.id })
            let newPersonas = validPersonas.filter { !existingIds.contains($0.id) }
            
            personas.append(contentsOf: newPersonas)
            savePersonas()
            
            print("📥 Persona import completed: \(newPersonas.count) items added")
            return true
            
        } catch {
            print("❌ Persona import error: \(error.localizedDescription)")
            return false
        }
    }
    
    // MARK: - Statistics Methods
    
    func getStatistics() -> PersonaStatistics {
        let relationshipCounts = Dictionary(grouping: personas, by: { $0.relationship })
            .mapValues { $0.count }
        
        let moodCounts = Dictionary(grouping: personas, by: { $0.mood })
            .mapValues { $0.count }
        
        return PersonaStatistics(
            totalCount: personas.count,
            relationshipDistribution: relationshipCounts,
            moodDistribution: moodCounts
        )
    }
}

// MARK: - Supporting Structures

struct PersonaStatistics {
    let totalCount: Int
    let relationshipDistribution: [String: Int]
    let moodDistribution: [PersonaMood: Int]
}

// MARK: - Extensions

extension PersonaManager {
    
    // Convenient properties
    var isEmpty: Bool {
        return personas.isEmpty
    }
    
    var hasDefaultPersona: Bool {
        return personas.contains { $0.id == UserPersona.defaultPersona.id }
    }
    
    // Get recently used personas (implementation example)
    func getRecentlyUsedPersonas(limit: Int = 5) -> [UserPersona] {
        // In actual implementation, recent usage history should be saved
        // Here's a simple implementation returning first N items
        return Array(personas.prefix(limit))
    }
    
    // Favorite persona management (for future feature expansion)
    func markAsFavorite(_ persona: UserPersona) {
        // Preparation for future favorite feature implementation
        print("⭐ Added to favorites: \(persona.name)")
    }
    
    func removeFromFavorites(_ persona: UserPersona) {
        // Preparation for future favorite feature implementation
        print("⭐ Removed from favorites: \(persona.name)")
    }
}
