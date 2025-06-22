import SwiftUI
import StoreKit

struct SubscriptionView: View {
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 32) {
                    // ヘッダー
                    headerView
                    
                    // 現在の状況
                    currentStatusView
                    
                    // プラン詳細
                    if let product = subscriptionManager.monthlyProduct {
                        planDetailsView(for: product)
                    } else {
                        ProgressView()
                            .padding()
                    }
                    
                    // 機能一覧
                    featuresView
                    
                    // アクションボタン
                    actionButtonsView
                    
                    // 注意事項
                    termsView
                }
                .padding()
            }
            .navigationTitle("サブスクリプション")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("閉じる") {
                        dismiss()
                    }
                }
            }
            .alert("エラー", isPresented: .constant(subscriptionManager.errorMessage != nil), actions: {
                Button("OK") { subscriptionManager.errorMessage = nil }
            }, message: {
                Text(subscriptionManager.errorMessage ?? "不明なエラーが発生しました。")
            })
        }
    }
    
    // MARK: - View Components
    
    private var headerView: some View {
        VStack(spacing: 16) {
            Image(systemName: "crown.fill")
                .font(.system(size: 60))
                .foregroundColor(.yellow)
            
            Text("AI機能を有効にする")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("サブスクリプションでAI機能を\n無制限にご利用いただけます")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }
    
    private var currentStatusView: some View {
        VStack(spacing: 16) {
            Text("現在の状況")
                .font(.headline)
                .fontWeight(.semibold)
            
            HStack {
                Image(systemName: subscriptionManager.subscriptionStatus.iconName)
                    .font(.title2)
                    .foregroundColor(subscriptionManager.subscriptionStatus.iconColor)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(subscriptionManager.subscriptionStatus.displayName)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text(subscriptionManager.subscriptionStatus.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if subscriptionManager.subscriptionStatus == .trial {
                        Text("残り \(subscriptionManager.getRemainingTrialDays()) 日")
                            .font(.caption)
                            .foregroundColor(.orange)
                            .fontWeight(.semibold)
                    }
                }
                
                Spacer()
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }
    
    private func planDetailsView(for product: Product) -> some View {
        VStack(spacing: 16) {
            Text("プラン詳細")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(product.displayName)
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Text(product.description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(product.displayPrice)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.blue)
                        
                        Text("/ 月")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                if let introductoryOffer = product.subscription?.introductoryOffer {
                    Divider()
                    HStack {
                        Text("\(introductoryOffer.paymentMode.localizedDescription) \(introductoryOffer.period.localizedDescription)")
                            .font(.subheadline)
                            .foregroundColor(.green)
                        Spacer()
                    }
                }
            }
            .padding()
            .background(Color.blue.opacity(0.1))
            .cornerRadius(12)
        }
    }
    
    private var featuresView: some View {
        VStack(spacing: 16) {
            Text("含まれる機能")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                FeatureRow(
                    icon: "brain.head.profile",
                    title: "AI会話",
                    description: "自然で人間らしい対話"
                )
                
                FeatureRow(
                    icon: "heart.fill",
                    title: "感情分析",
                    description: "豊かな感情の交流"
                )
                
                FeatureRow(
                    icon: "memorychip",
                    title: "会話の記憶",
                    description: "過去の会話を覚えています"
                )
                
                FeatureRow(
                    icon: "person.crop.circle.badge.plus",
                    title: "無制限のペルソナ",
                    description: "好きなだけキャラクターを作成"
                )
                
                FeatureRow(
                    icon: "infinity",
                    title: "無制限の会話",
                    description: "回数制限なしで会話を楽しめます"
                )
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }
    
    private var actionButtonsView: some View {
        VStack(spacing: 16) {
            Button(action: {
                Task {
                    await subscriptionManager.purchaseSubscription()
                }
            }) {
                HStack {
                    if subscriptionManager.isLoading {
                        ProgressView()
                    } else {
                        Text("サブスクリプションを開始")
                            .fontWeight(.semibold)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(subscriptionManager.subscriptionStatus == .active ? Color.gray : Color.accentColor)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .disabled(subscriptionManager.subscriptionStatus == .active || subscriptionManager.isLoading)
            
            Button("購入を復元") {
                Task {
                    await subscriptionManager.restorePurchases()
                }
            }
            .tint(.secondary)
        }
    }
    
    private var termsView: some View {
        VStack(spacing: 8) {
            Text("2日間の無料トライアル終了後、自動的に月額料金が課金されます。お支払いはApple IDアカウントに請求されます。サブスクリプションは、現在の期間が終了する少なくとも24時間前にキャンセルされない限り、自動的に更新されます。")
                .font(.caption2)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            HStack {
                if let url = URL(string: "https://tegujupe222.github.io/privacy-policy/") {
                    Link("プライバシーポリシー", destination: url)
                }
                Spacer()
                if let url = URL(string: "https://tegujupe222.github.io/privacy-policy/terms.html") {
                    Link("利用規約", destination: url)
                }
            }
            .font(.caption)
            .padding(.top, 8)
        }
    }
}

// MARK: - Feature Row

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

// MARK: - Helper Extensions

extension SubscriptionStatus {
    var iconName: String {
        switch self {
        case .unknown: return "questionmark.circle.fill"
        case .trial: return "hourglass.circle.fill"
        case .active: return "checkmark.circle.fill"
        case .expired: return "xmark.circle.fill"
        }
    }
    
    var iconColor: Color {
        switch self {
        case .unknown: return .gray
        case .trial: return .orange
        case .active: return .green
        case .expired: return .red
        }
    }
}

@available(iOS 15.0, *)
extension StoreKit.Product.SubscriptionOffer.PaymentMode {
    var localizedDescription: String {
        switch self {
        case .payAsYouGo: return "都度払い"
        case .payUpFront: return "前払い"
        case .freeTrial: return "無料トライアル"
        default: return ""
        }
    }
}

extension StoreKit.Product.SubscriptionPeriod {
    var localizedDescription: String {
        let format = "%d%@"
        switch self.unit {
        case .day: return String(format: format, self.value, "日間")
        case .week: return String(format: format, self.value, "週間")
        case .month: return String(format: format, self.value, "ヶ月間")
        case .year: return String(format: format, self.value, "年間")
        @unknown default: return ""
        }
    }
}

struct SubscriptionView_Previews: PreviewProvider {
    static var previews: some View {
        SubscriptionView()
    }
} 