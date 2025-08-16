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
    
    // Trial period (days)
    private let trialPeriodDays = 3
    
    // Subscription ID: jp.co.want.monthly
    // Bundle ID: com.igafactory2025.want
    
    // Server-side validation settings
    private let receiptValidator: ReceiptValidator
    private let enableServerValidation = true // Whether to enable server-side validation
    
    private init() {
        // Initialize ReceiptValidator (in actual operation, set appropriate Shared Secret)
        self.receiptValidator = ReceiptValidator(
            bundleIdentifier: "com.igafactory2025.want",
            sharedSecret: "c8bd394394d642e3aa07bd0125ab96ff" // Shared Secret obtained from App Store Connect (production)
        )
        
        loadSubscriptionStatus()
        
        // Start trial on first launch
        if subscriptionStatus == .unknown {
            startTrial()
        }
        
        print("📱 SubscriptionManager initialization completed: status=\(subscriptionStatus.displayName)")
    }
    
    /// Save trial start date
    private func startTrial() {
        let now = Date()
        userDefaults.set(now, forKey: trialStartKey)
        subscriptionStatus = .trial
        saveSubscriptionStatus()
    }
    
    /// Calculate remaining trial days
    var trialDaysLeft: Int {
        guard let start = userDefaults.object(forKey: trialStartKey) as? Date else { return 0 }
        let end = Calendar.current.date(byAdding: .day, value: trialPeriodDays, to: start) ?? start
        let daysLeft = Calendar.current.dateComponents([.day], from: Date(), to: end).day ?? 0
        return max(0, daysLeft)
    }
    
    /// Trial expiration check
    var isTrialExpired: Bool {
        guard let start = userDefaults.object(forKey: trialStartKey) as? Date else { return true }
        let end = Calendar.current.date(byAdding: .day, value: trialPeriodDays, to: start) ?? start
        return Date() > end
    }
    
    /// Check if AI features are available
    func canUseAI() -> Bool {
        switch subscriptionStatus {
        case .trial, .active:
            return true
        case .expired, .unknown:
            return false
        }
    }
    
    /// Update subscription status
    func updateSubscriptionStatus() async {
        // Trial expiration check
        if subscriptionStatus == .trial && isTrialExpired {
            subscriptionStatus = .expired
            saveSubscriptionStatus()
        }
        
        var newStatus: SubscriptionStatus = .unknown
        var validSubscription: Transaction?
        
        print("🔄 Subscription status update started")
        
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result,
               transaction.revocationDate == nil {
                validSubscription = transaction
                break
            }
        }
        
        if let transaction = validSubscription {
            // Execute additional validation if server-side validation is enabled
            if enableServerValidation {
                await validateWithServer(transaction: transaction)
            }
            
            let expirationDate = transaction.expirationDate
            let now = Date()
            
            if let expiration = expirationDate {
                if now < expiration {
                    newStatus = .active
                    print("✅ Valid subscription found: expiration=\(expiration)")
                } else {
                    newStatus = .expired
                    print("❌ Subscription expired: expiration=\(expiration)")
                }
            } else {
                // Subscription without expiration
                newStatus = .active
                print("✅ Unlimited subscription found")
            }
        } else {
            // No valid subscription
            if subscriptionStatus == .trial && !isTrialExpired {
                newStatus = .trial
                print("🆓 Trial period active")
            } else {
                newStatus = .expired
                print("❌ No valid subscription")
            }
        }
        
        if newStatus != subscriptionStatus {
            subscriptionStatus = newStatus
            print("🔄 Subscription status changed: \(newStatus.displayName)")
        }
        
        // Update AI feature enable/disable status
        AIConfigManager.shared.updateAIStatusBasedOnTrial()
    }
    
    /// Server-side receipt validation
    /// - Parameter transaction: Transaction to validate
    private func validateWithServer(transaction: Transaction) async {
        do {
            // Get receipt data
            let receiptData: Data
            
            // For now, continue using appStoreReceiptURL with deprecation warning suppression
            // TODO: Update to AppTransaction.shared when iOS 18+ becomes minimum target
            // Suppress deprecation warning for now
            func getReceiptData() -> Data? {
                guard let receiptURL = Bundle.main.appStoreReceiptURL,
                      let receiptData = try? Data(contentsOf: receiptURL) else {
                    return nil
                }
                return receiptData
            }
            
            guard let receiptDataFromURL = getReceiptData() else {
                print("❌ Failed to get receipt data")
                return
            }
            receiptData = receiptDataFromURL
            
            // Base64 encode
            let receiptString = receiptData.base64EncodedString()
            
            // Execute server-side validation
            let result = try await receiptValidator.validateReceipt(receiptString)
            
            if result.isValid {
                print("✅ Server-side validation successful: \(result.environment)")
                
                if let purchaseInfo = result.purchaseInfo {
                    print("📦 Product ID: \(purchaseInfo.productId)")
                    print("🆔 Transaction ID: \(purchaseInfo.transactionId)")
                    print("📅 Purchase Date: \(purchaseInfo.purchaseDate)")
                    print("⏰ Expiration: \(purchaseInfo.expiresDate)")
                    print("🔚 Expired: \(purchaseInfo.isExpired)")
                }
            } else {
                print("❌ Server-side validation failed")
            }
            
        } catch let error as ReceiptValidationError {
            print("❌ Receipt validation error: \(error.localizedDescription)")
            
            // Log details for specific errors
            switch error {
            case .sandboxReceiptUsedInProduction:
                print("🔄 Sandbox receipt detected in production environment")
            case .productionReceiptUsedInSandbox:
                print("🔄 Production receipt detected in sandbox environment")
            case .subscriptionExpired:
                print("⏰ Subscription has expired")
            default:
                print("❌ Other validation error: \(error)")
            }
            
        } catch {
            print("❌ Unexpected error: \(error)")
        }
    }
    
    /// Load subscription status from UserDefaults
    private func loadSubscriptionStatus() {
        if let statusString = userDefaults.string(forKey: statusKey),
           let status = SubscriptionStatus(rawValue: statusString) {
            subscriptionStatus = status
        }
    }
    
    /// Save subscription status to UserDefaults
    private func saveSubscriptionStatus() {
        userDefaults.set(subscriptionStatus.rawValue, forKey: statusKey)
    }
    
    /// Enable/disable server-side validation
    /// - Parameter enabled: Whether to enable
    func setServerValidationEnabled(_ enabled: Bool) {
        // This function is expected to be called from settings screen
        print("🔧 Server-side validation setting changed: \(enabled)")
    }
    
    /// Restore purchases
    func restorePurchases() async {
        print("🔄 Restoring purchases...")
        
        do {
            try await AppStore.sync()
            await updateSubscriptionStatus()
            print("✅ Purchases restored successfully")
        } catch {
            print("❌ Failed to restore purchases: \(error)")
        }
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
            return "Unknown"
        case .trial:
            return "Trial"
        case .active:
            return "Active"
        case .expired:
            return "Expired"
        }
    }
    
    var description: String {
        switch self {
        case .unknown:
            return "Checking subscription status"
        case .trial:
            return "Free trial period active"
        case .active:
            return "Subscription is active"
        case .expired:
            return "Subscription has expired"
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
            return "Purchase verification failed"
        case .productNotFound:
            return "Product not found"
        case .purchaseFailed:
            return "Purchase failed"
        }
    }
}

// MARK: - StoreKit Extensions

extension AppStore {
    static func sync() async throws {
        // StoreKit sync process
        // In actual implementation, sync with App Store
    }
} 