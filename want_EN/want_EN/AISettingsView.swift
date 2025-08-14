import SwiftUI

// MARK: - AI Settings View

struct AISettingsView: View {
    @ObservedObject var aiConfigManager = AIConfigManager.shared
    @ObservedObject var subscriptionManager = SubscriptionManager.shared
    @State private var showingVercelURLAlert = false
    @State private var tempVercelURL = ""
    
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
            
            Section(header: Text("Vercel Proxy Configuration")) {
                HStack {
                    Text("Vercel Base URL")
                    Spacer()
                    if aiConfigManager.currentConfig.vercelBaseURL.isEmpty {
                        Text("Not set")
                            .foregroundColor(.red)
                    } else {
                        Text("Set")
                            .foregroundColor(.green)
                    }
                }
                
                Button(aiConfigManager.currentConfig.vercelBaseURL.isEmpty ? "Set Vercel URL" : "Update Vercel URL") {
                    tempVercelURL = aiConfigManager.currentConfig.vercelBaseURL
                    showingVercelURLAlert = true
                }
                .foregroundColor(.blue)
                
                if !aiConfigManager.currentConfig.vercelBaseURL.isEmpty {
                    Button("Clear Vercel URL") {
                        aiConfigManager.updateVercelBaseURL("")
                    }
                    .foregroundColor(.red)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Gemini 2.5 Flash Lite via Vercel")
                        .font(.headline)
                    Text("Secure AI model access through Vercel proxy")
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
        .alert("Vercel Base URL", isPresented: $showingVercelURLAlert) {
            TextField("Enter Vercel Base URL", text: $tempVercelURL)
            Button("Cancel", role: .cancel) { }
            Button("Save") {
                aiConfigManager.updateVercelBaseURL(tempVercelURL)
            }
        } message: {
            Text("Enter your Vercel deployment URL (e.g., https://your-project.vercel.app)")
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
