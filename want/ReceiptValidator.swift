import Foundation

/// サーバーサイドでのレシート検証を行うクラス
class ReceiptValidator {
    
    // MARK: - Constants
    
    /// Appleのレシート検証エンドポイント
    private enum Endpoint {
        static let production = "https://buy.itunes.apple.com/verifyReceipt"
        static let sandbox = "https://sandbox.itunes.apple.com/verifyReceipt"
    }
    
    /// Appleのレスポンスステータスコード
    enum StatusCode: Int {
        case valid = 0
        case sandboxReceiptUsedInProduction = 21007
        case productionReceiptUsedInSandbox = 21008
        case invalidReceipt = 21002
        case unauthorized = 21003
        case serverUnavailable = 21005
        case subscriptionExpired = 21006
        case testReceipt = 21010
        case serverError = 21199
    }
    
    // MARK: - Properties
    
    private let bundleIdentifier: String
    private let sharedSecret: String
    
    // MARK: - Initialization
    
    init(bundleIdentifier: String, sharedSecret: String) {
        self.bundleIdentifier = bundleIdentifier
        self.sharedSecret = sharedSecret
    }
    
    // MARK: - Public Methods
    
    /// レシートを検証する（App Store Connectガイドライン準拠）
    /// まず本番用 App Store に対して検証を行い、
    /// 「Sandbox receipt used in production」というエラーが返ってきた場合のみ、サンドボックス環境で再検証する
    /// - Parameter receiptData: レシートデータ（Base64エンコードされた文字列）
    /// - Returns: 検証結果
    func validateReceipt(_ receiptData: String) async throws -> ReceiptValidationResult {
        print("🔍 レシート検証開始")
        
        // まず本番用 App Store に対して検証を行う
        do {
            print("🌐 本番環境で検証を開始")
            let result = try await validateReceipt(receiptData, environment: .production)
            print("✅ 本番環境での検証成功")
            return result
        } catch let error as ReceiptValidationError {
            // 「Sandbox receipt used in production」というエラーが返ってきた場合のみ、サンドボックス環境で再検証
            if error.statusCode == .sandboxReceiptUsedInProduction {
                print("🔄 Sandbox receipt used in production エラーを検出")
                print("🔄 Sandbox環境で再検証を開始")
                let sandboxResult = try await validateReceipt(receiptData, environment: .sandbox)
                print("✅ Sandbox環境での検証成功")
                return sandboxResult
            }
            // その他のエラーはそのまま投げる
            print("❌ レシート検証エラー: \(error.localizedDescription)")
            throw error
        }
    }
    
    // MARK: - Private Methods
    
    /// 特定の環境でレシートを検証
    /// - Parameters:
    ///   - receiptData: レシートデータ
    ///   - environment: 検証環境
    /// - Returns: 検証結果
    private func validateReceipt(_ receiptData: String, environment: ReceiptValidationEnvironment) async throws -> ReceiptValidationResult {
        let endpoint = environment == .production ? Endpoint.production : Endpoint.sandbox
        
        // リクエストボディを作成
        let requestBody: [String: Any] = [
            "receipt-data": receiptData,
            "password": sharedSecret,
            "exclude-old-transactions": true
        ]
        
        // JSONエンコード
        let jsonData = try JSONSerialization.data(withJSONObject: requestBody)
        
        // URLリクエストを作成
        guard let url = URL(string: endpoint) else {
            throw ReceiptValidationError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        
        // ネットワークリクエスト実行
        let (data, response) = try await URLSession.shared.data(for: request)
        
        // HTTPレスポンスチェック
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ReceiptValidationError.networkError
        }
        
        guard httpResponse.statusCode == 200 else {
            throw ReceiptValidationError.serverError(httpResponse.statusCode)
        }
        
        // JSONデコード
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let json = json else {
            throw ReceiptValidationError.invalidResponse
        }
        
        // ステータスコードを取得
        guard let statusCode = json["status"] as? Int else {
            throw ReceiptValidationError.invalidResponse
        }
        
        // ステータスコードをチェック
        guard let status = StatusCode(rawValue: statusCode) else {
            throw ReceiptValidationError.unknownStatus(statusCode)
        }
        
        // エラーハンドリング
        switch status {
        case .valid:
            return try parseReceiptResponse(json)
        case .sandboxReceiptUsedInProduction:
            throw ReceiptValidationError.sandboxReceiptUsedInProduction
        case .productionReceiptUsedInSandbox:
            throw ReceiptValidationError.productionReceiptUsedInSandbox
        case .invalidReceipt:
            throw ReceiptValidationError.invalidReceipt
        case .unauthorized:
            throw ReceiptValidationError.unauthorized
        case .serverUnavailable:
            throw ReceiptValidationError.serverUnavailable
        case .subscriptionExpired:
            throw ReceiptValidationError.subscriptionExpired
        case .testReceipt:
            throw ReceiptValidationError.testReceipt
        case .serverError:
            throw ReceiptValidationError.serverError(statusCode)
        }
    }
    
    /// レシートレスポンスをパース
    /// - Parameter json: AppleからのレスポンスJSON
    /// - Returns: パースされた結果
    private func parseReceiptResponse(_ json: [String: Any]) throws -> ReceiptValidationResult {
        // レシート情報を取得
        guard let receipt = json["receipt"] as? [String: Any] else {
            throw ReceiptValidationError.invalidResponse
        }
        
        // バンドルIDを検証
        guard let bundleId = receipt["bundle_id"] as? String,
              bundleId == bundleIdentifier else {
            throw ReceiptValidationError.bundleIdMismatch
        }
        
        // 最新の購入情報を取得
        guard let latestReceiptInfo = json["latest_receipt_info"] as? [[String: Any]],
              let latestInfo = latestReceiptInfo.first else {
            throw ReceiptValidationError.noPurchaseInfo
        }
        
        // 購入情報をパース
        let purchaseInfo = try parsePurchaseInfo(latestInfo)
        
        return ReceiptValidationResult(
            isValid: true,
            environment: json["environment"] as? String ?? "unknown",
            purchaseInfo: purchaseInfo
        )
    }
    
    /// 購入情報をパース
    /// - Parameter info: 購入情報の辞書
    /// - Returns: パースされた購入情報
    private func parsePurchaseInfo(_ info: [String: Any]) throws -> PurchaseInfo {
        guard let productId = info["product_id"] as? String,
              let transactionId = info["transaction_id"] as? String,
              let purchaseDateString = info["purchase_date_ms"] as? String,
              let expiresDateString = info["expires_date_ms"] as? String else {
            throw ReceiptValidationError.invalidPurchaseInfo
        }
        
        // 日付を変換（オプショナル値を安全に処理）
        guard let purchaseDateDouble = Double(purchaseDateString),
              let expiresDateDouble = Double(expiresDateString) else {
            throw ReceiptValidationError.invalidPurchaseInfo
        }
        
        let purchaseDate = Date(timeIntervalSince1970: purchaseDateDouble / 1000.0)
        let expiresDate = Date(timeIntervalSince1970: expiresDateDouble / 1000.0)
        
        return PurchaseInfo(
            productId: productId,
            transactionId: transactionId,
            purchaseDate: purchaseDate,
            expiresDate: expiresDate,
            isExpired: Date() > expiresDate
        )
    }
}

// MARK: - Supporting Types

/// 検証環境
enum ReceiptValidationEnvironment {
    case production
    case sandbox
}

/// レシート検証結果
struct ReceiptValidationResult {
    let isValid: Bool
    let environment: String
    let purchaseInfo: PurchaseInfo?
}

/// 購入情報
struct PurchaseInfo {
    let productId: String
    let transactionId: String
    let purchaseDate: Date
    let expiresDate: Date
    let isExpired: Bool
}

/// レシート検証エラー
enum ReceiptValidationError: LocalizedError {
    case invalidURL
    case networkError
    case serverError(Int)
    case invalidResponse
    case unknownStatus(Int)
    case sandboxReceiptUsedInProduction
    case productionReceiptUsedInSandbox
    case invalidReceipt
    case unauthorized
    case serverUnavailable
    case subscriptionExpired
    case testReceipt
    case bundleIdMismatch
    case noPurchaseInfo
    case invalidPurchaseInfo
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "無効なURLです"
        case .networkError:
            return "ネットワークエラーが発生しました"
        case .serverError(let code):
            return "サーバーエラーが発生しました (コード: \(code))"
        case .invalidResponse:
            return "無効なレスポンスです"
        case .unknownStatus(let code):
            return "不明なステータスコード: \(code)"
        case .sandboxReceiptUsedInProduction:
            return "Sandboxレシートが本番環境で使用されました"
        case .productionReceiptUsedInSandbox:
            return "本番レシートがSandbox環境で使用されました"
        case .invalidReceipt:
            return "無効なレシートです"
        case .unauthorized:
            return "認証に失敗しました"
        case .serverUnavailable:
            return "サーバーが利用できません"
        case .subscriptionExpired:
            return "サブスクリプションが期限切れです"
        case .testReceipt:
            return "テストレシートです"
        case .bundleIdMismatch:
            return "バンドルIDが一致しません"
        case .noPurchaseInfo:
            return "購入情報が見つかりません"
        case .invalidPurchaseInfo:
            return "無効な購入情報です"
        }
    }
    
    var statusCode: ReceiptValidator.StatusCode? {
        switch self {
        case .sandboxReceiptUsedInProduction:
            return .sandboxReceiptUsedInProduction
        case .productionReceiptUsedInSandbox:
            return .productionReceiptUsedInSandbox
        case .invalidReceipt:
            return .invalidReceipt
        case .unauthorized:
            return .unauthorized
        case .serverUnavailable:
            return .serverUnavailable
        case .subscriptionExpired:
            return .subscriptionExpired
        case .testReceipt:
            return .testReceipt
        default:
            return nil
        }
    }
} 