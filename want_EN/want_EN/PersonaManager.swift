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
        print("👥 PersonaManager初期化完了")
    }
    
    // MARK: - Public Methods
    
    func addPersona(_ persona: UserPersona) {
        var safePersona = persona
        safePersona.customization.makeSafe()
        
        personas.append(safePersona)
        savePersonas()
        print("➕ ペルソナ追加: \(safePersona.name)")
    }
    
    func updatePersona(_ persona: UserPersona) {
        if let index = personas.firstIndex(where: { $0.id == persona.id }) {
            var safePersona = persona
            safePersona.customization.makeSafe()
            
            personas[index] = safePersona
            savePersonas()
            print("🔄 ペルソナ更新: \(safePersona.name)")
            
            // PersonaLoaderにも更新を通知（メインアクターで実行）
            Task { @MainActor in
                PersonaLoader.shared.refreshCurrentPersona()
            }
        }
    }
    
    func deletePersona(_ persona: UserPersona) {
        personas.removeAll { $0.id == persona.id }
        
        // ✅ 関連する画像ファイルも削除
        if let imageFileName = persona.customization.avatarImageFileName {
            ImageManager.shared.deleteAvatarImage(fileName: imageFileName)
        }
        
        savePersonas()
        print("🗑️ ペルソナ削除: \(persona.name)")
        
        // 削除されたペルソナが現在選択中の場合、PersonaLoaderを更新
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
        // 基本的な妥当性チェック
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
            print("🧹 無効なペルソナをクリーンアップ: \(originalCount - personas.count)件削除")
        }
    }
    
    // MARK: - Private Methods
    
    private func savePersonas() {
        do {
            // 保存前に妥当性チェック
            let validPersonas = personas.compactMap { persona in
                var validPersona = persona
                validPersona.customization.makeSafe()
                return validatePersona(validPersona) ? validPersona : nil
            }
            
            let data = try JSONEncoder().encode(validPersonas)
            userDefaults.set(data, forKey: personasKey)
            print("💾 ペルソナ保存完了: \(validPersonas.count)件")
        } catch {
            print("❌ ペルソナ保存エラー: \(error.localizedDescription)")
            // エラー発生時は既存データを保護（何もしない）
        }
    }
    
    private func loadPersonas() {
        guard let data = userDefaults.data(forKey: personasKey) else {
            print("📱 保存されたペルソナなし - デフォルトペルソナを作成")
            createDefaultPersonas()
            return
        }
        
        do {
            let loadedPersonas = try JSONDecoder().decode([UserPersona].self, from: data)
            
            // 読み込んだペルソナの妥当性をチェック
            personas = loadedPersonas.compactMap { persona in
                var validPersona = persona
                validPersona.customization.makeSafe()
                
                // 妥当性チェック
                if validatePersona(validPersona) {
                    return validPersona
                } else {
                    print("⚠️ 無効なペルソナをスキップ: \(persona.name)")
                    return nil
                }
            }
            
            // ペルソナが一つもない場合はデフォルトを作成
            if personas.isEmpty {
                print("⚠️ 有効なペルソナが見つからないため、デフォルトを作成")
                createDefaultPersonas()
            } else {
                print("📱 ペルソナ読み込み完了: \(personas.count)件")
            }
            
        } catch {
            print("❌ ペルソナ読み込みエラー: \(error.localizedDescription)")
            // エラー時はデフォルトペルソナを作成
            createDefaultPersonas()
        }
    }
    
    private func createDefaultPersonas() {
        let defaultPersonas = [
            UserPersona(
                name: "お母さん",
                relationship: "家族",
                personality: ["優しい", "心配性", "愛情深い"],
                speechStyle: "温かく包み込むような口調",
                catchphrases: ["大丈夫よ", "お疲れさま"],
                favoriteTopics: ["日常の出来事", "健康", "家族のこと"],
                mood: .happy,
                customization: PersonaCustomization(
                    avatarEmoji: "👩",
                    avatarColor: Color.personaPink
                )
            ),
            UserPersona(
                name: "友達",
                relationship: "親友",
                personality: ["明るい", "親しみやすい", "ユーモアがある"],
                speechStyle: "カジュアルで親しみやすい",
                catchphrases: ["そうなんだ〜", "すごいじゃん！"],
                favoriteTopics: ["趣味", "エンタメ", "恋愛"],
                mood: .excited,
                customization: PersonaCustomization(
                    avatarEmoji: "😊",
                    avatarColor: Color.personaLightBlue
                )
            ),
            UserPersona(
                name: "先生",
                relationship: "恩師",
                personality: ["知的", "優しい", "指導力がある"],
                speechStyle: "丁寧で落ち着いた口調",
                catchphrases: ["なるほど", "素晴らしいですね"],
                favoriteTopics: ["学習", "成長", "将来の目標"],
                mood: .calm,
                customization: PersonaCustomization(
                    avatarEmoji: "👨‍🏫",
                    avatarColor: Color.personaLightGreen
                )
            )
        ]
        
        personas = defaultPersonas
        savePersonas()
        print("🆕 デフォルトペルソナ作成完了: \(defaultPersonas.count)件")
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
    
    // ✅ 未使用画像のクリーンアップ
    func cleanupUnusedImages() {
        let existingPersonaIds = personas.map { $0.id }
        ImageManager.shared.cleanupUnusedImages(existingPersonaIds: existingPersonaIds)
        print("🧹 未使用画像のクリーンアップ完了")
    }
    
    // MARK: - Export/Import Methods
    
    func exportPersonasData() -> Data? {
        do {
            return try JSONEncoder().encode(personas)
        } catch {
            print("❌ ペルソナエクスポートエラー: \(error.localizedDescription)")
            return nil
        }
    }
    
    func importPersonasData(_ data: Data) -> Bool {
        do {
            let importedPersonas = try JSONDecoder().decode([UserPersona].self, from: data)
            
            // インポートしたペルソナの妥当性をチェック
            let validPersonas = importedPersonas.compactMap { persona in
                var validPersona = persona
                validPersona.customization.makeSafe()
                return validatePersona(validPersona) ? validPersona : nil
            }
            
            // 既存のペルソナと重複しないようにIDをチェック
            let existingIds = Set(personas.map { $0.id })
            let newPersonas = validPersonas.filter { !existingIds.contains($0.id) }
            
            personas.append(contentsOf: newPersonas)
            savePersonas()
            
            print("📥 ペルソナインポート完了: \(newPersonas.count)件追加")
            return true
            
        } catch {
            print("❌ ペルソナインポートエラー: \(error.localizedDescription)")
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
    
    // 便利なプロパティ
    var isEmpty: Bool {
        return personas.isEmpty
    }
    
    var hasDefaultPersona: Bool {
        return personas.contains { $0.id == UserPersona.defaultPersona.id }
    }
    
    // 最近使用したペルソナを取得（実装例）
    func getRecentlyUsedPersonas(limit: Int = 5) -> [UserPersona] {
        // 実際の実装では最近の使用履歴を保存する必要があります
        // ここでは先頭から指定数を返す簡単な実装
        return Array(personas.prefix(limit))
    }
    
    // お気に入りペルソナの管理（将来の機能拡張用）
    func markAsFavorite(_ persona: UserPersona) {
        // 将来的にお気に入り機能を実装する場合の準備
        print("⭐ お気に入りに追加: \(persona.name)")
    }
    
    func removeFromFavorites(_ persona: UserPersona) {
        // 将来的にお気に入り機能を実装する場合の準備
        print("⭐ お気に入りから削除: \(persona.name)")
    }
}
