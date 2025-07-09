import SwiftUI

@main
struct WantENApp: App {
    @StateObject private var chatViewModel = ChatViewModel()
    @StateObject private var personaLoader = PersonaLoader.shared
    @StateObject private var chatRoomManager = ChatRoomManager()
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    
    // ✅ App lifecycle monitoring
    @Environment(\.scenePhase) private var scenePhase
    
    init() {
        print("🚀 WantENApp initialization started")
        print("🚀 WantENApp initialization completed")
    }
    
    var body: some Scene {
        WindowGroup {
            // ✅ Simple splash screen support
            MainAppWithSplashView()
                .environmentObject(chatViewModel)
                .environmentObject(personaLoader)
                .environmentObject(chatRoomManager)
                .onChange(of: scenePhase) { oldValue, newValue in
                    handleScenePhaseChange(oldValue: oldValue, newValue: newValue)
                }
        }
    }
    
    // ✅ More reliable lifecycle change handling
    private func handleScenePhaseChange(oldValue: ScenePhase?, newValue: ScenePhase) {
        print("🔄 ScenePhase change: \(oldValue?.description ?? "nil") → \(newValue.description)")
        
        switch newValue {
        case .background:
            print("🔄 App transitioning to background - saving data immediately")
            saveAllData()
            
        case .inactive:
            print("🔄 App becoming inactive - saving data immediately")
            saveAllData()
            
        case .active:
            print("🔄 App becoming active again")
            // Recheck data when becoming active
            chatViewModel.printDebugInfo()
            
        @unknown default:
            print("🔄 Unknown ScenePhase: \(newValue)")
            break
        }
    }
    
    // ✅ Reliable data saving
    private func saveAllData() {
        print("💾 Starting data save")
        
        // Save ChatViewModel
        chatViewModel.saveOnAppWillTerminate()
        
        // Force UserDefaults synchronization
        UserDefaults.standard.synchronize()
        
        print("💾 Data save completed")
    }
}

// ✅ Main view with splash screen
struct MainAppWithSplashView: View {
    @State private var showingSplash = true
    @EnvironmentObject var chatViewModel: ChatViewModel
    @EnvironmentObject var personaLoader: PersonaLoader
    @EnvironmentObject var chatRoomManager: ChatRoomManager
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    
    var body: some View {
        Group {
            if showingSplash {
                // ✅ Show splash screen
                SplashScreenView {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        showingSplash = false
                    }
                }
            } else {
                // ✅ Main app screen
                AppContentView()
                    .environmentObject(chatViewModel)
                    .environmentObject(personaLoader)
                    .environmentObject(chatRoomManager)
                    .onAppear {
                        print("📱 ContentView display started")
                        
                        // Check subscription status
                        Task {
                            await subscriptionManager.updateSubscriptionStatus()
                            print("📱 Subscription status: \(subscriptionManager.subscriptionStatus)")
                            print("📱 AI available: \(subscriptionManager.canUseAI())")
                        }
                    }
            }
        }
    }
}

// ✅ Simple splash screen
struct SplashScreenView: View {
    @State private var isLoading = true
    @State private var iconScale: CGFloat = 0.8
    @State private var iconOpacity: Double = 0.0
    
    var onFinish: () -> Void
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(.systemBackground),
                    Color.pink.opacity(0.05),
                    Color(.systemBackground)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 40) {
                Spacer()
                
                // App icon section
                VStack(spacing: 30) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [.pink.opacity(0.2), .purple.opacity(0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 140, height: 140)
                        
                        Image(systemName: "heart.fill")
                            .font(.system(size: 35))
                            .foregroundColor(.pink)
                            .offset(x: -10, y: -5)
                        
                        Image(systemName: "paperplane.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.blue)
                            .offset(x: 15, y: 10)
                            .rotationEffect(.degrees(-15))
                    }
                    .scaleEffect(iconScale)
                    .opacity(iconOpacity)
                    
                    VStack(spacing: 12) {
                        Text("I want to talk with you again...")
                            .font(.title2)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                        
                        Text("Relive precious moments with loved ones")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .opacity(iconOpacity)
                }
                
                Spacer()
                
                if isLoading {
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.2)
                            .tint(.pink)
                        
                        Text("Starting up...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .opacity(iconOpacity)
                }
            }
            .padding()
        }
        .onAppear {
            startAnimation()
        }
    }
    
    private func startAnimation() {
        // Icon animation
        withAnimation(.easeOut(duration: 0.8)) {
            iconScale = 1.0
            iconOpacity = 1.0
        }
        
        // Loading animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.easeInOut(duration: 0.3)) {
                isLoading = false
            }
            
            // Finish splash screen
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                onFinish()
            }
        }
    }
}

// ✅ Debug version AppContentView (staged PersonaManager initialization)
struct AppContentView: View {
    @EnvironmentObject var chatViewModel: ChatViewModel
    @EnvironmentObject var personaLoader: PersonaLoader
    @EnvironmentObject var chatRoomManager: ChatRoomManager
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    
    @State private var selectedTab: Int = 0
    @State private var isAppReady = false
    
    var body: some View {
        ZStack {
            if isAppReady {
                // ✅ Show tab view after app is ready
                TabView(selection: $selectedTab) {
                    // ChatRoomListView
                    ChatRoomListView()
                        .environmentObject(chatRoomManager)
                        .environmentObject(personaLoader)
                        .environmentObject(chatViewModel)
                        .tabItem {
                            Label("Chat", systemImage: "message")
                        }
                        .tag(0)
                    
                    // Persona management
                    PersonaListView()
                        .tabItem {
                            Label("People", systemImage: "person.2")
                        }
                        .tag(1)
                    
                    // Settings screen
                    AppSettingsView()
                        .environmentObject(chatViewModel)
                        .tabItem {
                            Label("Settings", systemImage: "gear")
                        }
                        .tag(2)
                }
            } else {
                // ✅ Initialization screen
                VStack(spacing: 20) {
                    ProgressView()
                        .scaleEffect(1.2)
                        .tint(.blue)
                    
                    Text("Preparing app...")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Text("Loading personas")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(.systemBackground))
            }
        }
        .onAppear {
            initializeApp()
        }
    }
    
    private func initializeApp() {
        print("🚀 App initialization started")
        
        Task { @MainActor in
            do {
                // ✅ Staged initialization
                print("📋 1. PersonaLoader initialization...")
                
                // Ensure PersonaLoader initialization
                if !personaLoader.hasCurrentPersona {
                    print("🔧 Setting default persona...")
                    personaLoader.setDefaultPersona()
                }
                
                // Wait a bit
                try await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
                
                print("📋 2. PersonaManager check...")
                
                // Check PersonaManager status (don't access directly)
                let personaCount = PersonaManager.shared.getPersonaCount()
                print("👥 PersonaManager persona count: \(personaCount)")
                
                // Wait a bit more
                try await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds
                
                print("📋 3. ChatViewModel initialization...")
                chatViewModel.printDebugInfo()
                
                // Subscription status check and initialization
                print("📋 4. Subscription status check...")
                
                // Force subscription status update
                await subscriptionManager.updateSubscriptionStatus()
                
                print("💳 Subscription status: \(subscriptionManager.subscriptionStatus.displayName)")
                print("💳 AI available: \(subscriptionManager.canUseAI())")
                
                // AI feature status check
                print("📋 5. AI feature status check...")
                let aiConfig = AIConfigManager.shared.currentConfig
                print("🤖 AI enabled: \(aiConfig.isAIEnabled)")
                print("🤖 AI provider: \(aiConfig.provider.displayName)")
                print("🤖 Cloud Function URL: \(aiConfig.cloudFunctionURL)")
                
                // AI feature connection test (run in background)
                print("📋 6. AI feature connection test started...")
                Task.detached(priority: .background) {
                    do {
                        let aiService = AIChatService()
                        let testResult = try await aiService.testConnection()
                        print("✅ AI connection test successful: \(testResult)")
                    } catch {
                        print("⚠️ AI connection test failed: \(error)")
                    }
                }
                
                // Initialization complete
                withAnimation(.easeInOut(duration: 0.5)) {
                    isAppReady = true
                }
                
                print("✅ App initialization completed")
                print("🚀 Current persona: \(personaLoader.currentPersonaName)")
                
            } catch {
                print("❌ Initialization error: \(error)")
                
                // Show app even if error occurs
                withAnimation(.easeInOut(duration: 0.5)) {
                    isAppReady = true
                }
            }
        }
    }
}

// Settings screen (simple version)
struct AppSettingsView: View {
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @State private var showingSubscriptionView = false
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    VStack(spacing: 0) {
                        HStack {
                            Image(systemName: "crown.fill")
                                .foregroundColor(.yellow)
                                .font(.title2)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Subscription")
                                    .font(.headline)
                                Text("Manage AI feature usage")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Button("Manage") {
                                showingSubscriptionView = true
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.small)
                        }
                        .padding(.vertical, 4)
                        
                        NavigationLink(destination: AISettingsView()) {
                            HStack {
                                Image(systemName: "slider.horizontal.3")
                                    .foregroundColor(.blue)
                                Text("Advanced Settings")
                            }
                        }
                    }
                } header: {
                    Text("AI Features")
                }
                
                Section {
                    VStack(spacing: 0) {
                        HStack {
                            Image(systemName: subscriptionStatusIcon)
                                .foregroundColor(subscriptionStatusColor)
                            Text("Current Status")
                            Spacer()
                            Text(subscriptionManager.subscriptionStatus.displayName)
                                .foregroundColor(subscriptionStatusColor)
                                .fontWeight(.semibold)
                        }
                        
                        if subscriptionManager.subscriptionStatus == .trial {
                            HStack {
                                Image(systemName: "clock.fill")
                                    .foregroundColor(.orange)
                                Text("Trial Period")
                                Spacer()
                                Text("\(SubscriptionManager.shared.trialDaysLeft) days left")
                                    .foregroundColor(.orange)
                                    .fontWeight(.semibold)
                            }
                        }
                    }
                } header: {
                    Text("Subscription Status")
                }
                
                Section {
                    VStack(spacing: 0) {
                        HStack {
                            Image(systemName: "info.circle")
                                .foregroundColor(.blue)
                            Text("Version")
                            Spacer()
                            Text("1.0.3")
                                .foregroundColor(.secondary)
                        }
                    }
                } header: {
                    Text("App Information")
                }
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showingSubscriptionView) {
                SubscriptionView()
            }
        }
    }
    
    private var subscriptionStatusIcon: String {
        switch subscriptionManager.subscriptionStatus {
        case .unknown:
            return "xmark.circle.fill"
        case .trial:
            return "clock.fill"
        case .active:
            return "checkmark.circle.fill"
        case .expired:
            return "exclamationmark.triangle.fill"
        }
    }
    
    private var subscriptionStatusColor: Color {
        switch subscriptionManager.subscriptionStatus {
        case .unknown:
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

// ✅ Debug ScenePhase extension
extension ScenePhase {
    var description: String {
        switch self {
        case .active:
            return "active"
        case .inactive:
            return "inactive"
        case .background:
            return "background"
        @unknown default:
            return "unknown"
        }
    }
}
