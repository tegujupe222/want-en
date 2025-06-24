import SwiftUI
import StoreKit
import WebKit

struct SubscriptionView: View {
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @State private var showingTerms = false
    @State private var showingPrivacyPolicy = false
    @State private var showingRestoreAlert = false
    @State private var showingReviewModeAlert = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // ヘッダー
                    VStack(spacing: 10) {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.yellow)
                        
                        Text("プレミアム機能")
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text("AIチャット機能を無制限でお楽しみください")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 20)
                    
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
                        
                        Text(subscriptionManager.subscriptionStatus.description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    // 審査モード切り替え（デバッグビルドのみ）
                    #if DEBUG
                    VStack(spacing: 8) {
                        Text("開発者向け設定")
                            .font(.headline)
                        
                        Button(action: {
                            showingReviewModeAlert = true
                        }) {
                            HStack {
                                Image(systemName: subscriptionManager.isReviewModeEnabled ? "eye.slash" : "eye")
                                Text(subscriptionManager.isReviewModeEnabled ? "審査モードを無効にする" : "審査モードを有効にする")
                            }
                            .foregroundColor(.blue)
                        }
                        .buttonStyle(.bordered)
                        
                        if subscriptionManager.isReviewModeEnabled {
                            Text("審査モードが有効です - AI機能が利用可能")
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    #endif
                    
                    // サブスクリプション情報
                    if let product = subscriptionManager.monthlyProduct {
                        VStack(spacing: 12) {
                            Text("月額プラン")
                                .font(.headline)
                            
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("無制限AIチャット")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                    
                                    Text("• 2日間の無料トライアル")
                                    Text("• 月額自動更新")
                                    Text("• いつでもキャンセル可能")
                                }
                                .font(.caption)
                                .foregroundColor(.secondary)
                                
                                Spacer()
                                
                                VStack(alignment: .trailing, spacing: 4) {
                                    Text(product.displayPrice)
                                        .font(.title2)
                                        .fontWeight(.bold)
                                    
                                    Text("月額")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            Button(action: {
                                Task {
                                    await subscriptionManager.purchaseSubscription()
                                }
                            }) {
                                HStack {
                                    if subscriptionManager.isLoading {
                                        ProgressView()
                                            .scaleEffect(0.8)
                                    } else {
                                        Image(systemName: "crown.fill")
                                    }
                                    Text("プレミアムにアップグレード")
                                        .fontWeight(.semibold)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.yellow)
                                .foregroundColor(.black)
                                .cornerRadius(12)
                            }
                            .disabled(subscriptionManager.isLoading)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                    
                    // 復元ボタン
                    Button(action: {
                        Task {
                            await subscriptionManager.restorePurchases()
                        }
                    }) {
                        HStack {
                            Image(systemName: "arrow.clockwise")
                            Text("購入を復元")
                        }
                        .foregroundColor(.blue)
                    }
                    .disabled(subscriptionManager.isLoading)
                    
                    // 利用規約とプライバシーポリシー
                    VStack(spacing: 12) {
                        Text("法的情報")
                            .font(.headline)
                        
                        VStack(spacing: 8) {
                            Button("利用規約") {
                                showingTerms = true
                            }
                            .foregroundColor(.blue)
                            
                            Button("プライバシーポリシー") {
                                showingPrivacyPolicy = true
                            }
                            .foregroundColor(.blue)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    // エラーメッセージ
                    if let errorMessage = subscriptionManager.errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                            .padding()
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(8)
                    }
                    
                    Spacer(minLength: 20)
                }
                .padding(.horizontal)
            }
            .navigationTitle("サブスクリプション")
            .navigationBarTitleDisplayMode(.inline)
        }
        .sheet(isPresented: $showingTerms) {
            NavigationView {
                WebView(url: URL(string: "https://tegujupe222.github.io/privacy-policy/terms.html")!)
                    .navigationTitle("利用規約")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("閉じる") {
                                showingTerms = false
                            }
                        }
                    }
            }
        }
        .sheet(isPresented: $showingPrivacyPolicy) {
            NavigationView {
                WebView(url: URL(string: "https://tegujupe222.github.io/privacy-policy/")!)
                    .navigationTitle("プライバシーポリシー")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("閉じる") {
                                showingPrivacyPolicy = false
                            }
                        }
                    }
            }
        }
        .alert("審査モード切り替え", isPresented: $showingReviewModeAlert) {
            Button("有効にする") {
                subscriptionManager.enableReviewMode()
            }
            Button("無効にする") {
                subscriptionManager.disableReviewMode()
            }
            Button("キャンセル", role: .cancel) { }
        } message: {
            Text("審査モードを切り替えますか？\n有効にすると、サブスクリプションなしでもAI機能が利用可能になります。")
        }
    }
    
    private var statusColor: Color {
        switch subscriptionManager.subscriptionStatus {
        case .unknown:
            return .gray
        case .trial:
            return .green
        case .active:
            return .blue
        case .expired:
            return .red
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

// MARK: - WebView for Terms and Privacy Policy
struct WebView: UIViewRepresentable {
    let url: URL
    
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.load(URLRequest(url: url))
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        // No updates needed
    }
} 