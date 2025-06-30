import SwiftUI
import StoreKit

struct SubscriptionView: View {
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var products: [Product] = []
    @State private var showingLegalView = false
    
    // プロダクトID（App Store Connectで設定したものに合わせてください。例: jp.co.want.monthly）
    private let productIDs = ["jp.co.want.monthly"]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // ヘッダー
                VStack(spacing: 8) {
                    Text("サブスクリプション")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("AI機能を無制限にご利用いただけます")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top)
                
                // 無料トライアルの案内（目立つ表示）
                if subscriptionManager.subscriptionStatus == .trial {
                    VStack(spacing: 12) {
                        HStack {
                            Image(systemName: "gift.fill")
                                .foregroundColor(.orange)
                            Text("無料トライアル中")
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(.orange)
                        }
                        
                        Text("残り\(subscriptionManager.trialDaysLeft)日間、すべての機能を無料でお試しいただけます")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        
                        Text("トライアル期間終了後は月額800円で継続利用できます")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                    )
                }
                
                // 現在の状態表示
                VStack(spacing: 8) {
                    Text("現在の状態")
                        .font(.headline)
                    HStack {
                        Circle()
                            .fill(statusColor)
                            .frame(width: 12, height: 12)
                        Text(subscriptionManager.subscriptionStatus.displayName)
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    if subscriptionManager.subscriptionStatus == .trial {
                        Text("無料トライアル中（残り\(subscriptionManager.trialDaysLeft)日）")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    } else {
                        Text(subscriptionManager.subscriptionStatus.description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                // サブスクリプション詳細情報
                VStack(spacing: 16) {
                    Text("サブスクリプション詳細")
                        .font(.headline)
                    
                    VStack(spacing: 12) {
                        // サブスクリプション名
                        SubscriptionInfoRow(
                            icon: "crown.fill",
                            title: "サブスクリプション名",
                            value: "月額プラン"
                        )
                        
                        // 期間
                        SubscriptionInfoRow(
                            icon: "calendar",
                            title: "期間",
                            value: "1ヶ月"
                        )
                        
                        // 価格
                        if let product = products.first {
                            SubscriptionInfoRow(
                                icon: "yensign.circle",
                                title: "価格",
                                value: "\(product.displayPrice) / 月"
                            )
                        } else {
                            SubscriptionInfoRow(
                                icon: "yensign.circle",
                                title: "価格",
                                value: "800円 / 月"
                            )
                        }
                        
                        // 無料トライアル
                        SubscriptionInfoRow(
                            icon: "gift",
                            title: "無料トライアル",
                            value: "3日間"
                        )
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                // プラン情報
                VStack(spacing: 16) {
                    Text("含まれる機能")
                        .font(.headline)
                    
                    VStack(spacing: 12) {
                        FeatureRow(icon: "brain.head.profile", title: "AIチャット", description: "高度なAIとの会話が可能")
                        FeatureRow(icon: "persona.2", title: "パーソナ設定", description: "AIの性格をカスタマイズ")
                        FeatureRow(icon: "memorychip", title: "記憶機能", description: "会話履歴を記憶・活用")
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                // プロダクト表示
                if !products.isEmpty {
                    VStack(spacing: 12) {
                        Text("利用可能なプラン")
                            .font(.headline)
                        
                        ForEach(products, id: \.id) { product in
                            VStack(spacing: 8) {
                                Text(product.displayName)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                Text(product.displayPrice)
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.accentColor)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(.systemGray5))
                            .cornerRadius(12)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
                
                // アクションボタン
                VStack(spacing: 12) {
                    Button(action: {
                        Task {
                            await purchaseSubscription()
                        }
                    }) {
                        HStack {
                            Image(systemName: "crown.fill")
                            Text("サブスクリプションを開始")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .disabled(isLoading || subscriptionManager.subscriptionStatus == .active)
                    
                    Button(action: {
                        Task {
                            isLoading = true
                            await subscriptionManager.restorePurchases()
                            isLoading = false
                        }
                    }) {
                        HStack {
                            Image(systemName: "arrow.clockwise")
                            Text("購入を復元")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.systemGray5))
                        .foregroundColor(.primary)
                        .cornerRadius(12)
                    }
                    .disabled(isLoading)
                    
                    // キャンセルボタン
                    Button(action: {
                        if let url = URL(string: "https://apps.apple.com/account/subscriptions") {
                            UIApplication.shared.open(url)
                        }
                    }) {
                        HStack {
                            Image(systemName: "xmark.circle")
                            Text("サブスクリプションをキャンセル")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.systemGray6))
                        .foregroundColor(.red)
                        .cornerRadius(12)
                    }
                    .disabled(isLoading)
                }
                
                // 法的文書へのリンク
                VStack(spacing: 12) {
                    Button(action: {
                        showingLegalView = true
                    }) {
                        HStack {
                            Image(systemName: "doc.text")
                            Text("利用規約・プライバシーポリシー")
                            Spacer()
                            Image(systemName: "chevron.right")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.systemGray6))
                        .foregroundColor(.primary)
                        .cornerRadius(12)
                    }
                    
                    Button(action: {
                        // ユーザープライバシー選択ページを開く
                        if let url = URL(string: "https://tegujupe222.github.io/privacy-policy/user-privacy-choices.html") {
                            UIApplication.shared.open(url)
                        }
                    }) {
                        HStack {
                            Image(systemName: "person.crop.circle.badge.checkmark")
                            Text("ユーザープライバシー選択")
                            Spacer()
                            Image(systemName: "chevron.right")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.systemGray6))
                        .foregroundColor(.primary)
                        .cornerRadius(12)
                    }
                }
                
                if isLoading {
                    ProgressView("処理中...")
                        .padding()
                }
                
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                        .padding()
                }
                
                Spacer(minLength: 20)
            }
            .padding(.horizontal)
        }
        .navigationTitle("サブスクリプション")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingLegalView) {
            NavigationView {
                LegalView()
                    .navigationTitle("法的文書")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("閉じる") {
                                showingLegalView = false
                            }
                        }
                    }
            }
        }
        .onAppear {
            Task {
                await loadProducts()
            }
        }
    }
    
    private var statusColor: Color {
        switch subscriptionManager.subscriptionStatus {
        case .active:
            return .green
        case .trial:
            return .orange
        case .expired, .unknown:
            return .red
        }
    }
    
    // プロダクトを読み込み
    private func loadProducts() async {
        do {
            products = try await Product.products(for: productIDs)
            print("📦 プロダクト読み込み完了: \(products.count)個")
            for product in products {
                print("📦 \(product.displayName): \(product.displayPrice)")
            }
        } catch {
            print("❌ プロダクト読み込みエラー: \(error)")
            errorMessage = "プロダクト情報の取得に失敗しました"
        }
    }
    
    // サブスクリプション購入
    private func purchaseSubscription() async {
        guard let product = products.first else {
            errorMessage = "利用可能なプロダクトがありません"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            print("🛒 購入開始: \(product.displayName)")
            let result = try await product.purchase()
            
            switch result {
            case .success(let verification):
                print("✅ 購入成功")
                
                // 購入の検証
                switch verification {
                case .verified(let transaction):
                    print("✅ 購入検証成功: \(transaction.id)")
                    
                    // サブスクリプション状態を更新
                    await subscriptionManager.updateSubscriptionStatus()
                    
                    // 成功メッセージ
                    errorMessage = "サブスクリプションが開始されました！"
                    
                case .unverified(_, let error):
                    print("❌ 購入検証失敗: \(error)")
                    errorMessage = "購入の検証に失敗しました"
                }
                
            case .userCancelled:
                print("❌ ユーザーが購入をキャンセル")
                errorMessage = "購入がキャンセルされました"
                
            case .pending:
                print("⏳ 購入が保留中")
                errorMessage = "購入が保留中です。後で確認してください"
                
            @unknown default:
                print("❌ 未知の購入結果")
                errorMessage = "購入処理でエラーが発生しました"
            }
            
        } catch {
            print("❌ 購入エラー: \(error)")
            errorMessage = "購入処理でエラーが発生しました: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.accentColor)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

struct SubscriptionInfoRow: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.accentColor)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            
            Spacer()
        }
    }
}

#Preview {
    NavigationView {
        SubscriptionView()
    }
} 