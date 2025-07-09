import SwiftUI
import StoreKit

struct SubscriptionView: View {
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var products: [Product] = []
    @State private var showingLegalView = false
    
    // Product IDs (adjust to match what you set in App Store Connect. Example: com.want.monthly)
    private let productIDs = ["com.want.monthly"]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 8) {
                    Text("Subscription")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Unlimited access to AI features")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top)
                
                // Free trial notice (prominent display)
                if subscriptionManager.subscriptionStatus == .trial {
                    VStack(spacing: 12) {
                        HStack {
                            Image(systemName: "gift.fill")
                                .foregroundColor(.orange)
                            Text("Free Trial Active")
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(.orange)
                        }
                        
                        Text("\(subscriptionManager.trialDaysLeft) days remaining to try all features for free")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        
                        Text("Continue with monthly subscription of $2.99 after trial ends")
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
                
                // Current status display
                VStack(spacing: 8) {
                    Text("Current Status")
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
                        Text("Free trial (\(subscriptionManager.trialDaysLeft) days left)")
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
                
                // Subscription details
                VStack(spacing: 16) {
                    Text("Subscription Details")
                        .font(.headline)
                    
                    VStack(spacing: 12) {
                        // Subscription name
                        SubscriptionInfoRow(
                            icon: "crown.fill",
                            title: "Subscription Name",
                            value: "Monthly Plan"
                        )
                        
                        // Duration
                        SubscriptionInfoRow(
                            icon: "calendar",
                            title: "Duration",
                            value: "1 Month"
                        )
                        
                        // Price
                        if let product = products.first {
                            SubscriptionInfoRow(
                                icon: "dollarsign.circle",
                                title: "Price",
                                value: "\(product.displayPrice) / month"
                            )
                        } else {
                            SubscriptionInfoRow(
                                icon: "dollarsign.circle",
                                title: "Price",
                                value: "$2.99 / month"
                            )
                        }
                        
                        // Free trial
                        SubscriptionInfoRow(
                            icon: "gift",
                            title: "Free Trial",
                            value: "3 Days"
                        )
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                // Plan information
                VStack(spacing: 16) {
                    Text("Included Features")
                        .font(.headline)
                    
                    VStack(spacing: 12) {
                        FeatureRow(icon: "brain.head.profile", title: "AI Chat", description: "Advanced conversations with AI")
                        FeatureRow(icon: "person.2", title: "Persona Settings", description: "Customize AI personality")
                        FeatureRow(icon: "memorychip", title: "Memory Function", description: "Remember and utilize conversation history")
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                // Product display
                if !products.isEmpty {
                    VStack(spacing: 12) {
                        Text("Available Plans")
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
                
                // Action buttons
                VStack(spacing: 12) {
                    Button(action: {
                        Task {
                            await purchaseSubscription()
                        }
                    }) {
                        HStack {
                            Image(systemName: "crown.fill")
                            Text("Start Subscription")
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
                            Text("Restore Purchases")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.systemGray5))
                        .foregroundColor(.primary)
                        .cornerRadius(12)
                    }
                    .disabled(isLoading)
                    
                    // Cancel button
                    Button(action: {
                        if let url = URL(string: "https://apps.apple.com/account/subscriptions") {
                            UIApplication.shared.open(url)
                        }
                    }) {
                        HStack {
                            Image(systemName: "xmark.circle")
                            Text("Cancel Subscription")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.systemGray6))
                        .foregroundColor(.red)
                        .cornerRadius(12)
                    }
                    .disabled(isLoading)
                }
                
                // Legal document links
                VStack(spacing: 12) {
                    Button(action: {
                        showingLegalView = true
                    }) {
                        HStack {
                            Image(systemName: "doc.text")
                            Text("Terms of Service & Privacy Policy")
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
                        // Open user privacy choices page
                        if let url = URL(string: "https://tegujupe222.github.io/privacy-policy/user-privacy-choices.html") {
                            UIApplication.shared.open(url)
                        }
                    }) {
                        HStack {
                            Image(systemName: "person.crop.circle.badge.checkmark")
                            Text("User Privacy Choices")
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
                    ProgressView("Processing...")
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
        .navigationTitle("Subscription")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingLegalView) {
            NavigationView {
                LegalView()
                    .navigationTitle("Legal Documents")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Close") {
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
    
    // Load products
    private func loadProducts() async {
        do {
            products = try await Product.products(for: productIDs)
            print("📦 Products loaded: \(products.count) items")
            for product in products {
                print("📦 \(product.displayName): \(product.displayPrice)")
            }
        } catch {
            print("❌ Product loading error: \(error)")
            errorMessage = "Failed to load product information"
        }
    }
    
    // Purchase subscription
    private func purchaseSubscription() async {
        guard let product = products.first else {
            errorMessage = "No available products"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            print("🛒 Starting purchase: \(product.displayName)")
            let result = try await product.purchase()
            
            switch result {
            case .success(let verification):
                print("✅ Purchase successful")
                
                // Verify purchase
                switch verification {
                case .verified(let transaction):
                    print("✅ Purchase verification successful: \(transaction.id)")
                    
                    // Update subscription status
                    await subscriptionManager.updateSubscriptionStatus()
                    
                    // Success message
                    errorMessage = "Subscription started successfully!"
                    
                case .unverified(_, let error):
                    print("❌ Purchase verification failed: \(error)")
                    errorMessage = "Purchase verification failed"
                }
                
            case .userCancelled:
                print("❌ User cancelled purchase")
                errorMessage = "Purchase was cancelled"
                
            case .pending:
                print("⏳ Purchase pending")
                errorMessage = "Purchase is pending. Please check later"
                
            @unknown default:
                print("❌ Unknown purchase result")
                errorMessage = "An error occurred during purchase"
            }
            
        } catch {
            print("❌ Purchase error: \(error)")
            errorMessage = "Purchase error: \(error.localizedDescription)"
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