import Foundation
import SwiftUI

@MainActor
class PersonaLoader: ObservableObject {
    static let shared = PersonaLoader()
    
    @Published var currentPersona: UserPersona? {
        didSet {
            Task {
                await saveCurrentPersona()
            }
            print("👤 currentPersona updated: \(currentPersona?.name ?? "nil")")
        }
    }
    
    @Published var isLoading = false
    
    private let userDefaults = UserDefaults.standard
    private let currentPersonaKey = "current_persona_id"
    
    private init() {
        loadCurrentPersona()
        
        // Ensure default persona is set
        if currentPersona == nil {
            print("⚠️ currentPersona is nil, setting default persona")
            setDefaultPersona()
        }
        
        print("👤 PersonaLoader initialization completed - currentPersona: \(currentPersona?.name ?? "nil")")
    }
    
    // MARK: - Public Methods
    
    func setCurrentPersona(_ persona: UserPersona?) {
        currentPersona = persona
        print("👤 Current persona changed: \(persona?.name ?? "none")")
    }
    
    func loadPersona(by id: String) {
        isLoading = true
        
        // Execute synchronously (remove async delay)
        if let persona = PersonaManager.shared.getPersona(by: id) {
            currentPersona = persona
            print("👤 Persona loaded: \(persona.name)")
        } else {
            print("⚠️ Persona not found: \(id)")
            setDefaultPersona()
        }
        isLoading = false
    }
    
    func refreshCurrentPersona() {
        guard let currentPersona = currentPersona else {
            print("⚠️ currentPersona is nil, setting default persona")
            setDefaultPersona()
            return
        }
        
        // Get latest info from PersonaManager
        if let updatedPersona = PersonaManager.shared.getPersona(by: currentPersona.id) {
            self.currentPersona = updatedPersona
            print("🔄 Updated current persona: \(updatedPersona.name)")
        } else {
            // Return to default if persona was deleted
            setDefaultPersona()
            print("⚠️ Persona was deleted, switching to default")
        }
    }
    
    func clearCurrentPersona() {
        currentPersona = nil
        print("👤 Cleared current persona")
    }
    
    func setDefaultPersona() {
        currentPersona = UserPersona.defaultPersona
        print("👤 Set default persona: \(UserPersona.defaultPersona.name)")
    }
    
    // MARK: - Private Methods
    
    private func saveCurrentPersona() async {
        if let persona = currentPersona {
            userDefaults.set(persona.id, forKey: currentPersonaKey)
        } else {
            userDefaults.removeObject(forKey: currentPersonaKey)
        }
    }
    
    private func loadCurrentPersona() {
        guard let personaId = userDefaults.string(forKey: currentPersonaKey) else {
            // Use default if no saved persona
            currentPersona = UserPersona.defaultPersona
            print("👤 No saved persona - using default")
            return
        }
        
        // Load persona from PersonaManager
        if let persona = PersonaManager.shared.getPersona(by: personaId) {
            currentPersona = persona
            print("👤 Loaded saved persona: \(persona.name)")
        } else {
            // Use default if persona not found
            currentPersona = UserPersona.defaultPersona
            print("⚠️ Saved persona not found, using default")
        }
    }
}

// MARK: - Extensions

extension PersonaLoader {
    // Convenient properties
    var hasCurrentPersona: Bool {
        return currentPersona != nil
    }
    
    var currentPersonaName: String {
        return currentPersona?.name ?? "No Persona"
    }
    
    var isDefaultPersona: Bool {
        guard let current = currentPersona else { return false }
        return current.id == UserPersona.defaultPersona.id
    }
    
    // Safe currentPersona getter
    var safeCurrentPersona: UserPersona {
        return currentPersona ?? UserPersona.defaultPersona
    }
}
