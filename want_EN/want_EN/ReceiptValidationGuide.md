# サーバーサイドレシート検証ガイド

## 概要

このガイドでは、iOSアプリでサーバーサイドでのレシート検証を実装し、Production（本番）アプリがAppleのテスト環境（Sandbox）からレシートを受け取った場合の適切な処理方法について説明します。

## 実装のポイント

### 1. 推奨アプローチ

推奨されるアプローチは以下の通りです：

1. **まず本番環境で検証**: Production App Storeに対してレシートを検証
2. **Sandboxエラーの場合のみ再検証**: 「Sandbox receipt used in production（本番環境でSandboxレシートが使用された）」というエラーコード（21007）が返ってきた場合にのみ、Sandbox環境で再検証
3. **適切なエラーハンドリング**: 各環境での検証結果を適切に処理

### 2. 実装された機能

#### ReceiptValidator.swift
- Production/Sandbox環境の自動判定
- 適切なエラーハンドリング
- 詳細なログ出力
- 購入情報の解析

#### SubscriptionManager.swift
- サーバーサイド検証の統合
- クライアントサイド検証との併用
- 開発者向け設定

## 使用方法

### 1. 基本的な使用方法

```swift
// ReceiptValidatorの初期化
let validator = ReceiptValidator(
    bundleIdentifier: "com.igafactory2025.want",
    sharedSecret: "YOUR_SHARED_SECRET_HERE"
)

// レシート検証の実行
do {
    let result = try await validator.validateReceipt(receiptData)
    if result.isValid {
        print("✅ 検証成功: \(result.environment)")
        // 購入情報の処理
        if let purchaseInfo = result.purchaseInfo {
            print("商品ID: \(purchaseInfo.productId)")
            print("期限: \(purchaseInfo.expiresDate)")
        }
    }
} catch let error as ReceiptValidationError {
    print("❌ 検証エラー: \(error.localizedDescription)")
}
```

### 2. SubscriptionManagerでの統合

```swift
// SubscriptionManagerは自動的にサーバーサイド検証を実行
await subscriptionManager.updateSubscriptionStatus()
```

### 3. 開発者設定での制御

```swift
// サーバーサイド検証の有効/無効を切り替え
subscriptionManager.setServerValidationEnabled(true)
```

## エラーハンドリング

### 主要なエラーコード

| エラーコード | 説明 | 対応方法 |
|-------------|------|----------|
| 0 | 正常 | 処理続行 |
| 21007 | Sandboxレシートが本番環境で使用 | Sandbox環境で再検証 |
| 21008 | 本番レシートがSandbox環境で使用 | Production環境で再検証 |
| 21002 | 無効なレシート | エラーとして処理 |
| 21003 | 認証失敗 | Shared Secretを確認 |
| 21006 | サブスクリプション期限切れ | 期限切れとして処理 |

### エラー処理の例

```swift
do {
    let result = try await validator.validateReceipt(receiptData)
    // 成功時の処理
} catch let error as ReceiptValidationError {
    switch error {
    case .sandboxReceiptUsedInProduction:
        print("🔄 Sandboxレシートを検出、Sandbox環境で再検証")
        // 自動的にSandbox環境で再検証される
        
    case .productionReceiptUsedInSandbox:
        print("🔄 本番レシートを検出、Production環境で再検証")
        // 自動的にProduction環境で再検証される
        
    case .subscriptionExpired:
        print("⏰ サブスクリプションが期限切れ")
        // 期限切れとして処理
        
    case .unauthorized:
        print("❌ 認証に失敗 - Shared Secretを確認してください")
        // 設定エラーとして処理
        
    default:
        print("❌ その他のエラー: \(error.localizedDescription)")
        // 一般的なエラー処理
    }
}
```

## 設定要件

### 1. App Store Connect設定

1. **Shared Secretの取得**:
   - App Store Connect → アプリ → App内課金 → App-Specific Shared Secret
   - または、App Store Connect → ユーザーとアクセス → キー → App Store Connect API

2. **バンドルIDの確認**:
   - プロジェクトのBundle Identifierと一致していることを確認

### 2. コード設定

```swift
// ReceiptValidatorの初期化時に適切な値を設定
let validator = ReceiptValidator(
    bundleIdentifier: "com.igafactory2025.want", // 実際のBundle ID
    sharedSecret: "YOUR_SHARED_SECRET_HERE"      // 実際のShared Secret
)
```

## セキュリティ考慮事項

### 1. Shared Secretの管理

- **開発時**: コード内にハードコード（デバッグ用）
- **本番時**: 環境変数や安全な方法で管理
- **推奨**: サーバーサイドでの管理

### 2. レシートデータの保護

- レシートデータは機密情報
- 適切な暗号化とセキュリティ対策を実装
- ログ出力時は注意が必要

## テスト方法

### 1. Sandbox環境でのテスト

1. **Sandboxアカウントの作成**:
   - App Store Connect → ユーザーとアクセス → Sandbox → テスター

2. **テスト購入の実行**:
   - Sandboxアカウントでアプリをインストール
   - テスト購入を実行
   - レシート検証の動作を確認

### 2. 本番環境でのテスト

1. **本番アプリの配布**:
   - TestFlightまたはApp Store経由で配布
   - 実際の購入でテスト

2. **エラーケースのテスト**:
   - 無効なレシート
   - 期限切れのサブスクリプション
   - ネットワークエラー

## トラブルシューティング

### よくある問題

1. **Shared Secretエラー**:
   - App Store Connectで正しいShared Secretを取得
   - コード内の値が正しいことを確認

2. **バンドルID不一致**:
   - プロジェクトのBundle IDとApp Store Connectの設定を確認
   - ReceiptValidatorの初期化時の値を確認

3. **ネットワークエラー**:
   - インターネット接続を確認
   - Appleのサーバーへのアクセスを確認

4. **Sandbox/Production環境の混在**:
   - アプリのビルド設定を確認
   - 適切な環境でのテストを実行

## パフォーマンス最適化

### 1. キャッシュ戦略

- 検証結果のキャッシュ
- 不要な再検証の回避
- 適切な更新頻度の設定

### 2. エラーハンドリング

- リトライ機能の実装
- 適切なタイムアウト設定
- ユーザー体験を考慮したエラー表示

## まとめ

この実装により、ProductionアプリがSandboxレシートを受け取った場合でも適切に処理できるようになります。重要なポイントは：

1. **自動環境判定**: まず本番環境で検証し、必要に応じてSandbox環境で再検証
2. **適切なエラーハンドリング**: 各エラーコードに応じた適切な処理
3. **セキュリティ**: Shared Secretの適切な管理
4. **テスト**: 両環境での十分なテスト

この実装により、ユーザー体験を損なうことなく、安全で信頼性の高いレシート検証が可能になります。 