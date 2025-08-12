import SwiftUI

// MARK: - AI Settings View

struct AISettingsView: View {
    @ObservedObject var aiConfigManager = AIConfigManager.shared
    @ObservedObject var subscriptionManager = SubscriptionManager.shared
    @State private var showingAPIKeyAlert = false
    @State private var tempAPIKey = ""
    
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
            
            Section(header: Text("Gemini 2.5 Flash Lite")) {
                HStack {
                    Text("API Key")
                    Spacer()
                    if aiConfigManager.currentConfig.geminiAPIKey.isEmpty {
                        Text("Not set")
                            .foregroundColor(.red)
                    } else {
                        Text("Set")
                            .foregroundColor(.green)
                    }
                }
                
                Button(aiConfigManager.currentConfig.geminiAPIKey.isEmpty ? "Set API Key" : "Update API Key") {
                    tempAPIKey = aiConfigManager.currentConfig.geminiAPIKey
                    showingAPIKeyAlert = true
                }
                .foregroundColor(.blue)
                
                if !aiConfigManager.currentConfig.geminiAPIKey.isEmpty {
                    Button("Clear API Key") {
                        aiConfigManager.updateGeminiAPIKey("")
                    }
                    .foregroundColor(.red)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Gemini 2.5 Flash Lite")
                        .font(.headline)
                    Text("Fast and efficient AI model for real-time conversations")
                        .font(.caption)
                        .foregroundColor(.secondary)
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
        .alert("Gemini API Key", isPresented: $showingAPIKeyAlert) {
            TextField("Enter API Key", text: $tempAPIKey)
            Button("Cancel", role: .cancel) { }
            Button("Save") {
                aiConfigManager.updateGeminiAPIKey(tempAPIKey)
            }
        } message: {
            Text("Enter your Gemini API key to use Gemini 2.5 Flash Lite")
        }
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
