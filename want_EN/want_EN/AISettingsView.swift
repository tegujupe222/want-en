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
            
            Section(header: Text("AI Configuration")) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Gemini 2.5 Flash Lite via Vercel")
                        .font(.headline)
                    Text("Secure AI model access through Vercel proxy")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        Text("Status:")
                        Spacer()
                        Text("Configured")
                            .foregroundColor(.green)
                            .fontWeight(.semibold)
                    }
                    .padding(.top, 4)
                }
                .padding(.vertical, 4)
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
            
            Section(header: Text("Connection Test")) {
                Button("Test AI Connection") {
                    Task {
                        await testAIConnection()
                    }
                }
                .foregroundColor(.blue)
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
    
    private func testAIConnection() async {
        do {
            let aiService = AIChatService()
            let success = try await aiService.testConnection()
            
            await MainActor.run {
                if success {
                    print("✅ AI connection test successful")
                } else {
                    print("❌ AI connection test failed")
                }
            }
        } catch {
            await MainActor.run {
                print("❌ AI connection test error: \(error)")
            }
        }
    }
}

struct AISettingsView_Previews: PreviewProvider {
    static var previews: some View {
        AISettingsView()
    }
}
