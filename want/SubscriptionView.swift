import SwiftUI

struct SubscriptionView: View {
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var showingPurchaseAlert = false
    @State private var showingRestoreAlert = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 32) {
                    // ヘッダー
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
                    
                    // 現在の状況
                    currentStatusView
                    
                    // プラン詳細
                    planDetailsView
                    
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
                    Button("完了") {
                        dismiss()
                    }
                }
            }
        }
        .alert("購入確認", isPresented: $showingPurchaseAlert) {
            Button("キャンセル", role: .cancel) {}
            Button("購入する") {
                Task {
                    await subscriptionManager.purchaseSubscription()
                }
            }
        } message: {
            Text("月額980円（税込）でAI機能を無制限にご利用いただけます。\n\n• 2日間の無料トライアル付き\n• 2日目以降は自動的に課金されます\n• いつでもキャンセル可能\n• キャンセル後も期間終了まで利用可能")
        }
        .alert("復元確認", isPresented: $showingRestoreAlert) {
            Button("キャンセル", role: .cancel) {}
            Button("復元する") {
                Task {
                    await subscriptionManager.restorePurchases()
                }
            }
        } message: {
            Text("以前に購入したサブスクリプションを復元しますか？")
        }
        .alert("エラー", isPresented: .constant(subscriptionManager.errorMessage != nil)) {
            Button("OK") {
                subscriptionManager.errorMessage = nil
            }
        } message: {
            if let errorMessage = subscriptionManager.errorMessage {
                Text(errorMessage)
            }
        }
    }
    
    // MARK: - View Components
    
    private var currentStatusView: some View {
        VStack(spacing: 16) {
            Text("現在の状況")
                .font(.headline)
                .fontWeight(.semibold)
            
            HStack {
                Image(systemName: statusIcon)
                    .font(.title2)
                    .foregroundColor(statusColor)
                
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
    
    private var planDetailsView: some View {
        VStack(spacing: 16) {
            Text("プラン詳細")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("月額プラン")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Text("AI機能無制限利用")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("¥980")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.blue)
                        
                        Text("月額")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("（税込）")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                
                Divider()
                
                HStack {
                    Text("2日間無料トライアル")
                        .font(.subheadline)
                        .foregroundColor(.green)
                    
                    Spacer()
                    
                    Text("その後自動課金")
                        .font(.caption)
                        .foregroundColor(.secondary)
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
            if subscriptionManager.subscriptionStatus == .trial || subscriptionManager.subscriptionStatus == .expired {
                Button(action: {
                    showingPurchaseAlert = true
                }) {
                    HStack {
                        if subscriptionManager.isLoading {
                            ProgressView()
                                .scaleEffect(0.8)
                                .foregroundColor(.white)
                        } else {
                            Text("サブスクリプションを開始")
                                .fontWeight(.semibold)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .disabled(subscriptionManager.isLoading)
            }
            
            Button(action: {
                showingRestoreAlert = true
            }) {
                Text("購入を復元")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.systemGray5))
                    .foregroundColor(.primary)
                    .cornerRadius(12)
            }
            .disabled(subscriptionManager.isLoading)
            
            if subscriptionManager.subscriptionStatus == .active {
                Button(action: {
                    dismiss()
                }) {
                    Text("完了")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
            }
        }
    }
    
    private var termsView: some View {
        VStack(spacing: 16) {
            Text("注意事項・キャンセルポリシー")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(alignment: .leading, spacing: 12) {
                // 基本注意事項
                VStack(alignment: .leading, spacing: 8) {
                    Text("基本事項")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text("• 2日間の無料トライアル後、自動的に課金されます")
                    Text("• サブスクリプションはいつでもキャンセルできます")
                    Text("• キャンセル後も期間終了まで機能をご利用いただけます")
                    Text("• プライバシーポリシーと利用規約に同意したものとみなします")
                }
                .font(.caption)
                .foregroundColor(.secondary)
                
                Divider()
                
                // キャンセルポリシー
                VStack(alignment: .leading, spacing: 8) {
                    Text("キャンセル方法")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text("1. iPhoneの「設定」アプリを開く")
                    Text("2. 画面最上部のApple IDをタップ")
                    Text("3. 「サブスクリプション」を選択")
                    Text("4. 「want」を選択して「キャンセル」をタップ")
                    Text("5. または「App Store」→「アカウント」→「サブスクリプション」からも可能")
                }
                .font(.caption)
                .foregroundColor(.secondary)
                
                Divider()
                
                // 返金ポリシー
                VStack(alignment: .leading, spacing: 8) {
                    Text("返金について")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text("• 期間終了後の自動更新分のみ返金対象となります")
                    Text("• 返金はApp Storeの返金ポリシーに従います")
                    Text("• 返金申請は購入後90日以内に限ります")
                    Text("• 詳細はApp Storeのサポートにお問い合わせください")
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }
    
    // MARK: - Computed Properties
    
    private var statusIcon: String {
        switch subscriptionManager.subscriptionStatus {
        case .none:
            return "xmark.circle.fill"
        case .trial:
            return "clock.fill"
        case .active:
            return "checkmark.circle.fill"
        case .expired:
            return "exclamationmark.triangle.fill"
        }
    }
    
    private var statusColor: Color {
        switch subscriptionManager.subscriptionStatus {
        case .none:
            return .red
        case .trial:
            return .orange
        case .active:
            return .green
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

#Preview {
    SubscriptionView()
} 