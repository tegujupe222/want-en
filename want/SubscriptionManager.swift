import Foundation
import StoreKit

enum SubscriptionStatus: Codable, Equatable {
    case unknown
    case trial
    case active
    case expired

    var displayName: String {
        switch self {
        case .unknown: return "不明"
        case .trial: return "無料トライアル中"
        case .active: return "サブスクリプション有効"
        case .expired: return "期限切れ"
        }
    }
    
    var description: String {
        switch self {
        case .unknown: return "サブスクリプションの状態を確認できません。"
        case .trial: return "すべてのAI機能をご利用いただけます。"
        case .active: return "すべてのAI機能をご利用いただけます。"
        case .expired: return "サブスクリプションの有効期限が切れています。"
        }
    }
}

@MainActor
class SubscriptionManager: ObservableObject {
    static let shared = SubscriptionManager()

    @Published var subscriptionStatus: SubscriptionStatus = .unknown
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // ストア製品情報を保持するプロパティ
    @Published var monthlyProduct: Product?

    // App Store Connectで設定した製品ID
    let monthlyProductID = "igafactory.want.premium.monthly"

    private var updates: Task<Void, Never>? = nil

    private let userDefaults = UserDefaults.standard
    private let subscriptionKey = "subscription_status"
    private let trialStartKey = "trialStartDate"
    private let subscriptionStartKey = "subscriptionStartDate"
    
    // 審査用デバッグモード
    private let debugModeKey = "debug_mode_enabled"
    private let reviewModeKey = "review_mode_enabled"

    private init() {
        updates = Task {
            for await result in Transaction.updates {
                do {
                    let transaction = try self.checkVerified(result)
                    await self.updateSubscriptionStatus()
                    await transaction.finish()
                } catch {
                    print("Transaction failed verification: \(error)")
                }
            }
        }
        
        Task {
            await retrieveProducts()
            await updateSubscriptionStatus()
            
            // 初回起動時はトライアルを開始（同期処理で確実に実行）
            await MainActor.run {
                if subscriptionStatus == .unknown {
                    print("🎁 初回起動のためトライアルを開始")
                    startTrial()
                }
            }
        }
    }
    
    deinit {
        updates?.cancel()
    }
    
    // MARK: - Debug and Review Mode
    
    /// デバッグモードが有効かどうかを確認
    var isDebugModeEnabled: Bool {
        get {
            #if DEBUG
            return true // デバッグビルドでは常に有効
            #else
            return userDefaults.bool(forKey: debugModeKey)
            #endif
        }
        set {
            userDefaults.set(newValue, forKey: debugModeKey)
        }
    }
    
    /// 審査モードが有効かどうかを確認
    var isReviewModeEnabled: Bool {
        get {
            return userDefaults.bool(forKey: reviewModeKey)
        }
        set {
            userDefaults.set(newValue, forKey: reviewModeKey)
        }
    }
    
    /// 審査用のデモモードを有効にする（審査員が機能をテストできるように）
    func enableReviewMode() {
        isReviewModeEnabled = true
        print("🔍 審査モードを有効にしました")
    }
    
    /// 審査用のデモモードを無効にする
    func disableReviewMode() {
        isReviewModeEnabled = false
        print("🔍 審査モードを無効にしました")
    }
    
    func purchaseSubscription() async {
        isLoading = true
        defer { isLoading = false }
        
        guard let product = monthlyProduct else {
            errorMessage = "製品情報の取得に失敗しました。"
            return
        }
        
        do {
            let result = try await product.purchase()
            
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await updateSubscriptionStatus()
                await transaction.finish()
            case .userCancelled:
                print("Purchase cancelled by user.")
            case .pending:
                print("Purchase is pending.")
            @unknown default:
                break
            }
        } catch {
            errorMessage = "購入処理に失敗しました: \(error.localizedDescription)"
        }
    }

    func restorePurchases() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            try await AppStore.sync()
            await updateSubscriptionStatus()
            errorMessage = "購入履歴を復元しました。" // 成功メッセージとして
        } catch {
            errorMessage = "購入の復元に失敗しました: \(error.localizedDescription)"
        }
    }
    
    func updateSubscriptionStatus() async {
        var newStatus: SubscriptionStatus = .unknown
        var validSubscription: Transaction?
        
        print("🔄 サブスクリプション状態更新開始")
        
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result,
               transaction.productID == monthlyProductID,
               !transaction.isUpgraded {
                validSubscription = transaction
                break
            }
        }
        
        if let transaction = validSubscription {
            if transaction.revocationDate == nil {
                // Check for introductory offer
                if transaction.offer?.type == .introductory {
                    newStatus = .trial
                    print("🔄 App Storeトライアル中")
                } else if let expirationDate = transaction.expirationDate, expirationDate > Date() {
                    newStatus = .active
                    print("🔄 アクティブなサブスクリプション")
                } else {
                    newStatus = .expired
                    print("🔄 サブスクリプション期限切れ")
                }
            } else {
                newStatus = .expired
                print("🔄 サブスクリプション取り消し")
            }
        } else {
            // Check for manual trial if no transaction is found
            if let trialStartDate = userDefaults.object(forKey: trialStartKey) as? Date {
                let trialEndDate = Calendar.current.date(byAdding: .day, value: 2, to: trialStartDate) ?? Date()
                let isTrialActive = trialEndDate > Date()
                
                print("🔄 手動トライアル確認: 開始日=\(trialStartDate), 終了日=\(trialEndDate), 有効=\(isTrialActive)")
                
                if isTrialActive {
                newStatus = .trial
                    print("🔄 手動トライアル中")
                } else {
                    newStatus = .expired
                    print("🔄 手動トライアル期限切れ")
                }
            } else {
                newStatus = .expired
                print("🔄 トライアル開始日なし")
            }
        }
        
        print("🔄 状態更新: \(subscriptionStatus) → \(newStatus)")
        self.subscriptionStatus = newStatus
        saveSubscriptionStatus()
    }
    
    func startTrial() {
        print("🎁 トライアル開始処理: 現在の状態 = \(subscriptionStatus)")
        
        if subscriptionStatus == .unknown || subscriptionStatus == .expired {
            userDefaults.set(Date(), forKey: trialStartKey)
            print("🎁 トライアル開始日時を設定: \(Date())")
            
            Task { 
                await updateSubscriptionStatus()
                print("🎁 トライアル開始後の状態: \(subscriptionStatus)")
            }
        } else {
            print("🎁 トライアル開始スキップ: 現在の状態 = \(subscriptionStatus)")
        }
    }
    
    func canUseAI() -> Bool {
        // デバッグモードまたは審査モードが有効な場合は常に許可
        if isDebugModeEnabled || isReviewModeEnabled {
            print("🔍 デバッグ/審査モードによりAI機能を許可")
            return true
        }
        
        return subscriptionStatus == .active || subscriptionStatus == .trial
    }

    func retrieveProducts() async {
        do {
            let products = try await Product.products(for: [monthlyProductID])
            if let product = products.first {
                self.monthlyProduct = product
            } else {
                print("Could not find product.")
            }
        } catch {
            print("Failed to retrieve products: \(error)")
        }
    }
    
    func getRemainingTrialDays() -> Int {
        guard let trialStartDate = userDefaults.object(forKey: trialStartKey) as? Date else { return 0 }
        guard let trialEndDate = Calendar.current.date(byAdding: .day, value: 2, to: trialStartDate) else { return 0 }
        let remaining = Calendar.current.dateComponents([.day], from: Date(), to: trialEndDate).day ?? 0
        return max(0, remaining)
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreKitError.unknown
        case .verified(let safe):
            return safe
        }
    }

    private func saveSubscriptionStatus() {
        if let encodedData = try? JSONEncoder().encode(subscriptionStatus) {
            userDefaults.set(encodedData, forKey: subscriptionKey)
        }
    }

    private func loadSubscriptionStatus() {
        if let savedData = userDefaults.data(forKey: subscriptionKey),
           let decodedStatus = try? JSONDecoder().decode(SubscriptionStatus.self, from: savedData) {
            self.subscriptionStatus = decodedStatus
        }
    }
}

// MARK: - Error Types

enum SubscriptionError: LocalizedError {
    case verificationFailed
    case productNotFound
    case purchaseFailed
    
    var errorDescription: String? {
        switch self {
        case .verificationFailed:
            return "購入の検証に失敗しました"
        case .productNotFound:
            return "商品が見つかりません"
        case .purchaseFailed:
            return "購入に失敗しました"
        }
    }
}

// MARK: - StoreKit Extensions

extension AppStore {
    static func sync() async throws {
        // StoreKit同期処理
        // 実際の実装では、App Storeとの同期を行う
    }
} 