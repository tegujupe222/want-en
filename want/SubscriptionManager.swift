import Foundation
import StoreKit

@MainActor
class SubscriptionManager: ObservableObject {
    static let shared = SubscriptionManager()
    
    @Published var isSubscribed = false
    @Published var subscriptionStatus: SubscriptionStatus = .none
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let userDefaults = UserDefaults.standard
    private let subscriptionKey = "subscription_status"
    private let trialStartKey = "trial_start_date"
    private let subscriptionStartKey = "subscription_start_date"
    
    // 管理者のAPIキー（実際の運用では環境変数や安全な方法で管理）
    private let adminAPIKey = "YOUR_ADMIN_API_KEY_HERE"
    
    // StoreKit関連
    private var products: [Product] = []
    private var purchasedProductIDs = Set<String>()
    private let subscriptionProductID = "com.yourapp.ai_subscription_monthly"
    
    private init() {
        loadSubscriptionStatus()
        setupStoreKit()
    }
    
    // MARK: - Public Methods
    
    func startTrial() {
        let trialStart = Date()
        userDefaults.set(trialStart, forKey: trialStartKey)
        subscriptionStatus = .trial
        saveSubscriptionStatus()
        
        print("🎉 無料トライアル開始: \(trialStart)")
    }
    
    func purchaseSubscription() async {
        isLoading = true
        errorMessage = nil
        
        do {
            // 商品情報を取得
            let products = try await Product.products(for: [subscriptionProductID])
            guard let product = products.first else {
                errorMessage = "商品が見つかりません"
                isLoading = false
                return
            }
            
            // 購入を実行
            let result = try await product.purchase()
            
            switch result {
            case .success(let verification):
                // 購入成功
                await handlePurchaseSuccess(verification)
            case .userCancelled:
                errorMessage = "購入がキャンセルされました"
            case .pending:
                errorMessage = "購入が保留中です"
            @unknown default:
                errorMessage = "予期しないエラーが発生しました"
            }
        } catch {
            errorMessage = "購入エラー: \(error.localizedDescription)"
            print("❌ サブスクリプション購入エラー: \(error)")
        }
        
        isLoading = false
    }
    
    func restorePurchases() async {
        isLoading = true
        errorMessage = nil
        
        do {
            try await AppStore.sync()
            await checkSubscriptionStatus()
        } catch {
            errorMessage = "復元エラー: \(error.localizedDescription)"
            print("❌ 購入復元エラー: \(error)")
        }
        
        isLoading = false
    }
    
    func checkSubscriptionStatus() async {
        // トライアル期間の確認
        if let trialStart = userDefaults.object(forKey: trialStartKey) as? Date {
            let trialEnd = Calendar.current.date(byAdding: .day, value: 2, to: trialStart) ?? Date()
            
            if Date() > trialEnd && subscriptionStatus == .trial {
                subscriptionStatus = .expired
                saveSubscriptionStatus()
                print("⏰ トライアル期間終了")
            }
        }
        
        // サブスクリプション状態の確認
        if subscriptionStatus == .active {
            await verifySubscriptionWithStoreKit()
        }
    }
    
    func canUseAI() -> Bool {
        switch subscriptionStatus {
        case .trial, .active:
            return true
        case .expired, .none:
            return false
        }
    }
    
    func getRemainingTrialDays() -> Int {
        guard let trialStart = userDefaults.object(forKey: trialStartKey) as? Date else {
            return 0
        }
        
        let trialEnd = Calendar.current.date(byAdding: .day, value: 2, to: trialStart) ?? Date()
        let remaining = Calendar.current.dateComponents([.day], from: Date(), to: trialEnd).day ?? 0
        
        return max(0, remaining)
    }
    
    // MARK: - Private Methods
    
    private func setupStoreKit() {
        // StoreKitの設定
        Task {
            await loadProducts()
            await checkSubscriptionStatus()
        }
    }
    
    private func loadSubscriptionStatus() {
        if let statusString = userDefaults.string(forKey: subscriptionKey),
           let status = SubscriptionStatus(rawValue: statusString) {
            subscriptionStatus = status
        } else {
            // 初回起動時はトライアル開始
            startTrial()
        }
        
        isSubscribed = canUseAI()
    }
    
    private func saveSubscriptionStatus() {
        userDefaults.set(subscriptionStatus.rawValue, forKey: subscriptionKey)
        isSubscribed = canUseAI()
    }
    
    private func loadProducts() async {
        do {
            products = try await Product.products(for: [subscriptionProductID])
            print("📦 商品読み込み完了: \(products.count)件")
        } catch {
            print("❌ 商品読み込みエラー: \(error)")
        }
    }
    
    private func handlePurchaseSuccess(_ verification: VerificationResult<Transaction>) async {
        do {
            let transaction = try checkVerified(verification)
            
            // 購入済み商品IDを更新
            purchasedProductIDs.insert(transaction.productID)
            
            // サブスクリプション状態を更新
            subscriptionStatus = .active
            let subscriptionStart = Date()
            userDefaults.set(subscriptionStart, forKey: subscriptionStartKey)
            saveSubscriptionStatus()
            
            // トランザクションを完了
            await transaction.finish()
            
            print("✅ サブスクリプション購入完了")
        } catch {
            errorMessage = "購入の検証に失敗しました"
            print("❌ 購入検証エラー: \(error)")
        }
    }
    
    private func verifySubscriptionWithStoreKit() async {
        // 購入済みトランザクションを確認
        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)
                
                if transaction.productID == subscriptionProductID {
                    // 有効なサブスクリプションが見つかった
                    purchasedProductIDs.insert(transaction.productID)
                    subscriptionStatus = .active
                    saveSubscriptionStatus()
                    print("✅ 有効なサブスクリプションを確認")
                    return
                }
            } catch {
                print("❌ トランザクション検証エラー: \(error)")
            }
        }
        
        // 有効なサブスクリプションが見つからない場合
        if subscriptionStatus == .active {
            subscriptionStatus = .expired
            saveSubscriptionStatus()
            print("⚠️ サブスクリプションが期限切れ")
        }
    }
    
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw SubscriptionError.verificationFailed
        case .verified(let safe):
            return safe
        }
    }
}

// MARK: - Subscription Status

enum SubscriptionStatus: String, CaseIterable {
    case none = "none"
    case trial = "trial"
    case active = "active"
    case expired = "expired"
    
    var displayName: String {
        switch self {
        case .none:
            return "未購入"
        case .trial:
            return "トライアル中"
        case .active:
            return "有効"
        case .expired:
            return "期限切れ"
        }
    }
    
    var description: String {
        switch self {
        case .none:
            return "AI機能を使用するにはサブスクリプションが必要です"
        case .trial:
            return "2日間の無料トライアル中です"
        case .active:
            return "サブスクリプションが有効です"
        case .expired:
            return "トライアル期間が終了しました"
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