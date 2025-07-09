import Foundation
import StoreKit

@MainActor
class SubscriptionManager: ObservableObject {
    static let shared = SubscriptionManager()
    
    @Published var subscriptionStatus: SubscriptionStatus = .unknown {
        didSet {
            saveSubscriptionStatus()
        }
    }
    
    private let userDefaults = UserDefaults.standard
    private let statusKey = "subscription_status"
    private let trialStartKey = "trial_start_date"
    
    // トライアル期間（日数）
    private let trialPeriodDays = 3
    
    // サブスクリプションID: jp.co.want.monthly
    // バンドルID: com.igafactory2025.want
    
    // サーバーサイド検証用の設定
    private let receiptValidator: ReceiptValidator
    private let enableServerValidation = true // サーバーサイド検証を有効にするかどうか
    
    private init() {
        // ReceiptValidatorを初期化（実際の運用では適切なShared Secretを設定）
        self.receiptValidator = ReceiptValidator(
            bundleIdentifier: "com.igafactory2025.want",
            sharedSecret: "c8bd394394d642e3aa07bd0125ab96ff" // App Store Connectで取得したShared Secret（本番用）
        )
        
        loadSubscriptionStatus()
        
        // 初回起動時はトライアル開始
        if subscriptionStatus == .unknown {
            startTrial()
        }
        
        print("📱 SubscriptionManager初期化完了: 状態=\(subscriptionStatus.displayName)")
    }
    
    /// トライアル開始日を保存
    private func startTrial() {
        let now = Date()
        userDefaults.set(now, forKey: trialStartKey)
        subscriptionStatus = .trial
        saveSubscriptionStatus()
    }
    
    /// トライアル残り日数を計算
    var trialDaysLeft: Int {
        guard let start = userDefaults.object(forKey: trialStartKey) as? Date else { return 0 }
        let end = Calendar.current.date(byAdding: .day, value: trialPeriodDays, to: start) ?? start
        let daysLeft = Calendar.current.dateComponents([.day], from: Date(), to: end).day ?? 0
        return max(0, daysLeft)
    }
    
    /// トライアル終了判定
    var isTrialExpired: Bool {
        guard let start = userDefaults.object(forKey: trialStartKey) as? Date else { return true }
        let end = Calendar.current.date(byAdding: .day, value: trialPeriodDays, to: start) ?? start
        return Date() > end
    }
    
    /// AI機能が利用可能かどうかを確認
    func canUseAI() -> Bool {
        switch subscriptionStatus {
        case .trial, .active:
            return true
        case .expired, .unknown:
            return false
        }
    }
    
    /// サブスクリプション状態を更新
    func updateSubscriptionStatus() async {
        // トライアル終了判定
        if subscriptionStatus == .trial && isTrialExpired {
            subscriptionStatus = .expired
            saveSubscriptionStatus()
        }
        
        var newStatus: SubscriptionStatus = .unknown
        var validSubscription: Transaction?
        
        print("🔄 サブスクリプション状態更新開始")
        
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result,
               transaction.revocationDate == nil {
                validSubscription = transaction
                break
            }
        }
        
        if let transaction = validSubscription {
            // サーバーサイド検証が有効な場合は追加検証を実行
            if enableServerValidation {
                await validateWithServer(transaction: transaction)
            }
            
            let expirationDate = transaction.expirationDate
            let now = Date()
            
            if let expiration = expirationDate {
                if now < expiration {
                    newStatus = .active
                    print("✅ 有効なサブスクリプションを発見: 期限=\(expiration)")
                } else {
                    newStatus = .expired
                    print("❌ サブスクリプション期限切れ: 期限=\(expiration)")
                }
            } else {
                // 期限なしのサブスクリプション
                newStatus = .active
                print("✅ 無期限サブスクリプションを発見")
            }
        } else {
            // 有効なサブスクリプションがない場合
            if subscriptionStatus == .trial && !isTrialExpired {
                newStatus = .trial
                print("🆓 トライアル期間中")
            } else {
                newStatus = .expired
                print("❌ 有効なサブスクリプションなし")
            }
        }
        
        if newStatus != subscriptionStatus {
            subscriptionStatus = newStatus
            print("🔄 サブスクリプション状態変更: \(newStatus.displayName)")
        }
        
        // AI機能の有効/無効を更新
        AIConfigManager.shared.updateAIStatusBasedOnTrial()
    }
    
    /// サーバーサイドでのレシート検証
    /// - Parameter transaction: 検証するトランザクション
    private func validateWithServer(transaction: Transaction) async {
        do {
            // レシートデータを取得
            guard let receiptURL = Bundle.main.appStoreReceiptURL,
                  let receiptData = try? Data(contentsOf: receiptURL) else {
                print("❌ レシートデータの取得に失敗")
                return
            }
            
            // Base64エンコード
            let receiptString = receiptData.base64EncodedString()
            
            // サーバーサイド検証を実行
            let result = try await receiptValidator.validateReceipt(receiptString)
            
            if result.isValid {
                print("✅ サーバーサイド検証成功: \(result.environment)")
                
                if let purchaseInfo = result.purchaseInfo {
                    print("📦 商品ID: \(purchaseInfo.productId)")
                    print("🆔 トランザクションID: \(purchaseInfo.transactionId)")
                    print("📅 購入日: \(purchaseInfo.purchaseDate)")
                    print("⏰ 期限: \(purchaseInfo.expiresDate)")
                    print("🔚 期限切れ: \(purchaseInfo.isExpired)")
                }
            } else {
                print("❌ サーバーサイド検証失敗")
            }
            
        } catch let error as ReceiptValidationError {
            print("❌ レシート検証エラー: \(error.localizedDescription)")
            
            // 特定のエラーの場合はログに詳細を記録
            switch error {
            case .sandboxReceiptUsedInProduction:
                print("🔄 Sandboxレシートが本番環境で検出されました")
            case .productionReceiptUsedInSandbox:
                print("🔄 本番レシートがSandbox環境で検出されました")
            case .subscriptionExpired:
                print("⏰ サブスクリプションが期限切れです")
            default:
                print("❌ その他の検証エラー: \(error)")
            }
            
        } catch {
            print("❌ 予期しないエラー: \(error)")
        }
    }
    
    /// サブスクリプション状態を保存
    private func saveSubscriptionStatus() {
        userDefaults.set(subscriptionStatus.rawValue, forKey: statusKey)
    }
    
    /// サブスクリプション状態を読み込み
    private func loadSubscriptionStatus() {
        let rawValue = userDefaults.string(forKey: statusKey) ?? ""
        subscriptionStatus = SubscriptionStatus(rawValue: rawValue) ?? .unknown
    }
    
    /// サブスクリプションを復元
    func restorePurchases() async {
        print("🔄 サブスクリプション復元開始")
        
        do {
            try await AppStore.sync()
            await updateSubscriptionStatus()
            print("✅ サブスクリプション復元完了")
        } catch {
            print("❌ サブスクリプション復元エラー: \(error)")
        }
    }
    
    /// サーバーサイド検証の有効/無効を切り替え
    /// - Parameter enabled: 有効にするかどうか
    func setServerValidationEnabled(_ enabled: Bool) {
        // この機能は設定画面から呼び出されることを想定
        print("🔧 サーバーサイド検証設定変更: \(enabled)")
    }
}

enum SubscriptionStatus: String, CaseIterable {
    case unknown = "unknown"
    case trial = "trial"
    case active = "active"
    case expired = "expired"
    
    var displayName: String {
        switch self {
        case .unknown:
            return "未確認"
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
        case .unknown:
            return "サブスクリプション状態を確認中です"
        case .trial:
            return "無料トライアル期間中です"
        case .active:
            return "サブスクリプションが有効です"
        case .expired:
            return "サブスクリプションが期限切れです"
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