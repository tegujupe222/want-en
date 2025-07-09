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
            print("👤 currentPersona更新: \(currentPersona?.name ?? "nil")")
        }
    }
    
    @Published var isLoading = false
    
    private let userDefaults = UserDefaults.standard
    private let currentPersonaKey = "current_persona_id"
    
    private init() {
        loadCurrentPersona()
        
        // デフォルトペルソナを確実に設定
        if currentPersona == nil {
            print("⚠️ currentPersonaがnilのため、デフォルトペルソナを設定")
            setDefaultPersona()
        }
        
        print("👤 PersonaLoader初期化完了 - currentPersona: \(currentPersona?.name ?? "nil")")
    }
    
    // MARK: - Public Methods
    
    func setCurrentPersona(_ persona: UserPersona?) {
        currentPersona = persona
        print("👤 現在のペルソナ変更: \(persona?.name ?? "なし")")
    }
    
    func loadPersona(by id: String) {
        isLoading = true
        
        // 同期的に処理を実行（非同期遅延を削除）
        if let persona = PersonaManager.shared.getPersona(by: id) {
            currentPersona = persona
            print("👤 ペルソナ読み込み完了: \(persona.name)")
        } else {
            print("⚠️ ペルソナが見つかりません: \(id)")
            setDefaultPersona()
        }
        isLoading = false
    }
    
    func refreshCurrentPersona() {
        guard let currentPersona = currentPersona else {
            print("⚠️ currentPersonaがnilのため、デフォルトペルソナを設定")
            setDefaultPersona()
            return
        }
        
        // PersonaManagerから最新の情報を取得
        if let updatedPersona = PersonaManager.shared.getPersona(by: currentPersona.id) {
            self.currentPersona = updatedPersona
            print("🔄 現在のペルソナを更新: \(updatedPersona.name)")
        } else {
            // ペルソナが削除された場合はデフォルトに戻す
            setDefaultPersona()
            print("⚠️ ペルソナが削除されたためデフォルトに変更")
        }
    }
    
    func clearCurrentPersona() {
        currentPersona = nil
        print("👤 現在のペルソナをクリア")
    }
    
    func setDefaultPersona() {
        currentPersona = UserPersona.defaultPersona
        print("👤 デフォルトペルソナを設定: \(UserPersona.defaultPersona.name)")
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
            // 保存されたペルソナがない場合はデフォルトを使用
            currentPersona = UserPersona.defaultPersona
            print("👤 保存されたペルソナなし - デフォルト使用")
            return
        }
        
        // PersonaManagerからペルソナを読み込み
        if let persona = PersonaManager.shared.getPersona(by: personaId) {
            currentPersona = persona
            print("👤 保存されたペルソナ読み込み: \(persona.name)")
        } else {
            // ペルソナが見つからない場合はデフォルトを使用
            currentPersona = UserPersona.defaultPersona
            print("⚠️ 保存されたペルソナが見つからないためデフォルトを使用")
        }
    }
}

// MARK: - Extensions

extension PersonaLoader {
    // 便利なプロパティ
    var hasCurrentPersona: Bool {
        return currentPersona != nil
    }
    
    var currentPersonaName: String {
        return currentPersona?.name ?? "ペルソナなし"
    }
    
    var isDefaultPersona: Bool {
        guard let current = currentPersona else { return false }
        return current.id == UserPersona.defaultPersona.id
    }
    
    // 安全なcurrentPersona取得
    var safeCurrentPersona: UserPersona {
        return currentPersona ?? UserPersona.defaultPersona
    }
}
