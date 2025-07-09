import SwiftUI

struct SettingsView: View {
    @StateObject private var aiConfigManager = AIConfigManager.shared
    @StateObject private var personaManager = PersonaManager.shared
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @State private var showingAISettings = false
    @State private var showingAbout = false
    @State private var showingDataExport = false
    @State private var serverValidationEnabled = true
    
    var body: some View {
        NavigationView {
            List {
                // AI Settings Section
                Section(header: Text("AI Features")) {
                    NavigationLink(destination: AISettingsView()) {
                        HStack {
                            Image(systemName: "brain.head.profile")
                                .foregroundColor(.blue)
                                .frame(width: 24)
                            
                            VStack(alignment: .leading) {
                                Text("AI Settings")
                                    .font(.body)
                                
                                Text(aiConfigManager.currentConfig.isAIEnabled ? "Enabled" : "Disabled")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                
                // Subscription Section
                Section(header: Text("Subscription")) {
                    HStack {
                        Image(systemName: "creditcard")
                            .foregroundColor(.green)
                            .frame(width: 24)
                        
                        VStack(alignment: .leading) {
                            Text("Current Status")
                                .font(.body)
                            
                            Text(subscriptionManager.subscriptionStatus.displayName)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                    
                    Button(action: {
                        Task {
                            await subscriptionManager.restorePurchases()
                        }
                    }) {
                        HStack {
                            Image(systemName: "arrow.clockwise")
                                .foregroundColor(.blue)
                                .frame(width: 24)
                            
                            Text("Restore Purchases")
                                .foregroundColor(.primary)
                        }
                    }
                }
                
                // Developer Settings Section (Debug only)
                #if DEBUG
                Section(header: Text("Developer Settings")) {
                    Toggle(isOn: $serverValidationEnabled) {
                        HStack {
                            Image(systemName: "checkmark.shield")
                                .foregroundColor(.orange)
                                .frame(width: 24)
                            
                            VStack(alignment: .leading) {
                                Text("Server-side Validation")
                                    .font(.body)
                                
                                Text("Enable server-side receipt validation")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .onChange(of: serverValidationEnabled) { newValue in
                        subscriptionManager.setServerValidationEnabled(newValue)
                    }
                    
                    Button(action: {
                        Task {
                            await subscriptionManager.updateSubscriptionStatus()
                        }
                    }) {
                        HStack {
                            Image(systemName: "arrow.clockwise.circle")
                                .foregroundColor(.purple)
                                .frame(width: 24)
                            
                            Text("Update Subscription Status")
                                .foregroundColor(.primary)
                        }
                    }
                }
                #endif
                
                // Data Management Section
                Section(header: Text("Data Management")) {
                    Button(action: {
                        showingDataExport = true
                    }) {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                                .foregroundColor(.green)
                                .frame(width: 24)
                            
                            Text("Export Data")
                                .foregroundColor(.primary)
                        }
                    }
                    
                    Button(action: clearAllData) {
                        HStack {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                                .frame(width: 24)
                            
                            Text("Delete All Data")
                                .foregroundColor(.red)
                        }
                    }
                }
                
                // App Information Section
                Section(header: Text("App Information")) {
                    HStack {
                        Image(systemName: "info.circle")
                            .foregroundColor(.blue)
                            .frame(width: 24)
                        
                        VStack(alignment: .leading) {
                            Text("Version")
                                .font(.body)
                            
                            Text("1.0.3")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                    
                    Button(action: {
                        showingAbout = true
                    }) {
                        HStack {
                            Image(systemName: "questionmark.circle")
                                .foregroundColor(.blue)
                                .frame(width: 24)
                            
                            Text("About This App")
                                .foregroundColor(.primary)
                        }
                    }
                }
                
                // Statistics Section
                Section(header: Text("Statistics")) {
                    HStack {
                        Image(systemName: "person.2")
                            .foregroundColor(.purple)
                            .frame(width: 24)
                        
                        VStack(alignment: .leading) {
                            Text("Created Personas")
                                .font(.body)
                            
                            Text("\(personaManager.personas.count) people")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                    
                    HStack {
                        Image(systemName: "message")
                            .foregroundColor(.orange)
                            .frame(width: 24)
                        
                        VStack(alignment: .leading) {
                            Text("Total Messages")
                                .font(.body)
                            
                            Text("Calculating...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                }
                
                // Subscription & Legal Information Section
                Section(header: Text("Legal Information")) {
                    NavigationLink(destination: CancellationPolicyView()) {
                        HStack {
                            Image(systemName: "doc.text")
                                .foregroundColor(.blue)
                                .frame(width: 24)
                            
                            Text("Cancellation Policy")
                                .foregroundColor(.primary)
                        }
                    }
                    
                    Button(action: {
                        // Open privacy policy
                        if let url = URL(string: "https://tegujupe222.github.io/privacy-policy/") {
                            UIApplication.shared.open(url)
                        }
                    }) {
                        HStack {
                            Image(systemName: "hand.raised")
                                .foregroundColor(.green)
                                .frame(width: 24)
                            
                            Text("Privacy Policy")
                                .foregroundColor(.primary)
                        }
                    }
                    
                    Button(action: {
                        // Open terms of service
                        if let url = URL(string: "https://tegujupe222.github.io/privacy-policy/terms.html") {
                            UIApplication.shared.open(url)
                        }
                    }) {
                        HStack {
                            Image(systemName: "doc.plaintext")
                                .foregroundColor(.orange)
                                .frame(width: 24)
                            
                            Text("Terms of Service")
                                .foregroundColor(.primary)
                        }
                    }
                    
                    Button(action: {
                        // Open user privacy choices page
                        if let url = URL(string: "https://tegujupe222.github.io/privacy-policy/user-privacy-choices.html") {
                            UIApplication.shared.open(url)
                        }
                    }) {
                        HStack {
                            Image(systemName: "person.crop.circle.badge.checkmark")
                                .foregroundColor(.purple)
                                .frame(width: 24)
                            
                            Text("User Privacy Choices")
                                .foregroundColor(.primary)
                        }
                    }
                }
            }
            .navigationTitle("Settings")
        }
        .sheet(isPresented: $showingAbout) {
            AboutView()
        }
        .actionSheet(isPresented: $showingDataExport) {
            ActionSheet(
                title: Text("Export Data"),
                message: Text("What data would you like to export?"),
                buttons: [
                    .default(Text("Persona Data")) {
                        exportPersonaData()
                    },
                    .default(Text("Conversation History")) {
                        exportConversationData()
                    },
                    .default(Text("All Data")) {
                        exportAllData()
                    },
                    .cancel()
                ]
            )
        }
    }
    
    // MARK: - Private Methods
    
    private func clearAllData() {
        // Implementation for confirmation alert needed
        personaManager.personas.removeAll()
        aiConfigManager.resetToDefaults()
    }
    
    private func exportPersonaData() {
        // Implementation for persona data export
        print("Exporting persona data")
    }
    
    private func exportConversationData() {
        // Implementation for conversation history export
        print("Exporting conversation history")
    }
    
    private func exportAllData() {
        // Implementation for all data export
        print("Exporting all data")
    }
}

// MARK: - About View

struct AboutView: View {
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // App icon
                    Image(systemName: "bubble.left.and.bubble.right.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.blue)
                    
                    // App name
                    Text("want")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    // Version
                    Text("Version 1.0.3")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    // Description
                    VStack(spacing: 16) {
                        Text("want is an app that lets you enjoy conversations with your own special people.")
                            .multilineTextAlignment(.center)
                        
                        Text("Create family, friends, lovers, and people with various relationships to experience conversations with unique personalities.")
                            .multilineTextAlignment(.center)
                    }
                    .font(.body)
                    .foregroundColor(.primary)
                    
                    // Feature introduction
                    VStack(alignment: .leading, spacing: 12) {
                        SettingsFeatureRow(
                            icon: "person.crop.circle.badge.plus",
                            title: "Persona Creation",
                            description: "Create characters freely"
                        )
                        
                        SettingsFeatureRow(
                            icon: "brain.head.profile",
                            title: "AI Conversations",
                            description: "Natural and human-like dialogue"
                        )
                        
                        SettingsFeatureRow(
                            icon: "heart.fill",
                            title: "Emotional Expression",
                            description: "Rich emotional exchange"
                        )
                        
                        SettingsFeatureRow(
                            icon: "lock.shield",
                            title: "Privacy Protection",
                            description: "Safely protect your data"
                        )
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("About This App")
            .navigationBarItems(
                trailing: Button("Done") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
}

struct SettingsFeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 24)
            
            VStack(alignment: .leading) {
                Text(title)
                    .font(.headline)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

// MARK: - Preview

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}

// MARK: - Cancellation Policy View

struct CancellationPolicyView: View {
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 16) {
                        Image(systemName: "doc.text")
                            .font(.system(size: 60))
                            .foregroundColor(.blue)
                        
                        Text("Cancellation Policy")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("We'll explain in detail about\nsubscription cancellation")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    
                    // Cancellation method
                    VStack(spacing: 16) {
                        Text("How to Cancel")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            CancellationStepRow(
                                number: "1",
                                title: "Open iPhone Settings app",
                                description: "Tap the Settings app from the home screen"
                            )
                            
                            CancellationStepRow(
                                number: "2",
                                title: "Tap Apple ID",
                                description: "Tap the Apple ID displayed at the top of the screen"
                            )
                            
                            CancellationStepRow(
                                number: "3",
                                title: "Select \"Subscriptions\"",
                                description: "Tap \"Subscriptions\" from the Apple ID settings screen"
                            )
                            
                            CancellationStepRow(
                                number: "4",
                                title: "Select \"want\" and cancel",
                                description: "Select \"want\" from the subscription list and tap \"Cancel\""
                            )
                            
                            CancellationStepRow(
                                number: "5",
                                title: "Alternative: From App Store",
                                description: "Also possible from App Store → Account → Subscriptions"
                            )
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                    
                    // Usage after cancellation
                    VStack(spacing: 16) {
                        Text("Usage After Cancellation")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            PolicyRow(
                                icon: "checkmark.circle.fill",
                                title: "Available until period ends",
                                description: "After cancellation, you can use all features during the already paid period"
                            )
                            
                            PolicyRow(
                                icon: "xmark.circle.fill",
                                title: "Auto-renewal stops",
                                description: "After the period ends, it won't automatically renew and AI features will be limited"
                            )
                            
                            PolicyRow(
                                icon: "arrow.clockwise",
                                title: "Can restart anytime",
                                description: "You can restart your subscription anytime after the period ends"
                            )
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                    
                    // About refunds
                    VStack(spacing: 16) {
                        Text("About Refunds")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            PolicyRow(
                                icon: "dollarsign.circle.fill",
                                title: "Refund eligible",
                                description: "Only automatic renewals after the period ends are eligible for refunds"
                            )
                            
                            PolicyRow(
                                icon: "clock.fill",
                                title: "Refund request period",
                                description: "Refund requests are limited to within 90 days of purchase"
                            )
                            
                            PolicyRow(
                                icon: "questionmark.circle.fill",
                                title: "Refund method",
                                description: "Refunds follow App Store refund policy. For details, please contact App Store support"
                            )
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                    
                    // Contact
                    VStack(spacing: 16) {
                        Text("Contact")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("• For subscription inquiries, please use App Store support")
                            Text("• For app feature inquiries, feel free to contact the developer")
                            Text("• For refund details, please check Apple's official guidelines")
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                }
                .padding()
            }
            .navigationTitle("Cancellation Policy")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                trailing: Button("Done") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
}

// MARK: - Cancellation Step Row

struct CancellationStepRow: View {
    let number: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 12) {
            Text(number)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .frame(width: 24, height: 24)
                .background(Color.blue)
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
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

// MARK: - Policy Row

struct PolicyRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
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
