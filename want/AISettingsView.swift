import SwiftUI

// MARK: - AI Settings View

struct AISettingsView: View {
    @ObservedObject var aiConfigManager = AIConfigManager.shared
    @ObservedObject var subscriptionManager = SubscriptionManager.shared
    
    var body: some View {
        Form {
            Section(header: Text("AI機能")) {
                Toggle(isOn: $aiConfigManager.currentConfig.isAIEnabled) {
                    Text("AIを有効にする")
                }
                .onChange(of: aiConfigManager.currentConfig.isAIEnabled) { _, newValue in
                    if newValue {
                        aiConfigManager.enableAI()
                    } else {
                        aiConfigManager.disableAI()
                    }
                }
            }
            
            Section(header: Text("サブスクリプション")) {
                switch subscriptionManager.subscriptionStatus {
                case .active:
                    Text("サブスクリプション: 有効")
                        .foregroundColor(.green)
                case .trial:
                    Text("サブスクリプション: トライアル中（残り\(subscriptionManager.trialDaysLeft)日）")
                        .foregroundColor(.orange)
                case .expired, .unknown:
                    Text("サブスクリプション: 未加入")
                        .foregroundColor(.red)
                }
                NavigationLink(destination: SubscriptionView()) {
                    Text("サブスクリプション管理")
                }
            }
            
            Section("デバッグ") {
                Button("設定をリセット") {
                aiConfigManager.resetToDefaults()
                }
                .foregroundColor(.red)
            }
        }
        .navigationTitle("AI設定")
    }
}

struct AISettingsView_Previews: PreviewProvider {
    static var previews: some View {
    AISettingsView()
    }
}
