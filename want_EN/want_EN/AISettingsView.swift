import SwiftUI

// MARK: - AI Settings View

struct AISettingsView: View {
    @ObservedObject var aiConfigManager = AIConfigManager.shared
    @ObservedObject var subscriptionManager = SubscriptionManager.shared
    
    var body: some View {
        Form {
            Section(header: Text("AI Features")) {
                Toggle(isOn: $aiConfigManager.currentConfig.isAIEnabled) {
                    Text("Enable AI")
                }
                .onChange(of: aiConfigManager.currentConfig.isAIEnabled) { _, newValue in
                    if newValue {
                        aiConfigManager.enableAI()
                    } else {
                        aiConfigManager.disableAI()
                    }
                }
            }
            
            Section(header: Text("Subscription")) {
                switch subscriptionManager.subscriptionStatus {
                case .active:
                    Text("Subscription: Active")
                        .foregroundColor(.green)
                case .trial:
                    Text("Subscription: Trial (\(subscriptionManager.trialDaysLeft) days left)")
                        .foregroundColor(.orange)
                case .expired, .unknown:
                    Text("Subscription: Not subscribed")
                        .foregroundColor(.red)
                }
                NavigationLink(destination: SubscriptionView()) {
                    Text("Manage Subscription")
                }
            }
            
            Section("Debug") {
                Button("Reset Settings") {
                aiConfigManager.resetToDefaults()
                }
                .foregroundColor(.red)
            }
        }
        .navigationTitle("AI Settings")
    }
}

struct AISettingsView_Previews: PreviewProvider {
    static var previews: some View {
    AISettingsView()
    }
}
