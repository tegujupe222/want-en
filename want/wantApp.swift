import SwiftUI

@main
struct WantApp: App {
    @StateObject private var chatViewModel = ChatViewModel()
    @StateObject private var personaLoader = PersonaLoader.shared
    @StateObject private var chatRoomManager = ChatRoomManager()
    
    // ✅ アプリのライフサイクル監視
    @Environment(\.scenePhase) private var scenePhase
    
    var body: some Scene {
        WindowGroup {
            // ✅ シンプルなスプラッシュスクリーン対応
            MainAppWithSplashView()
                .environmentObject(chatViewModel)
                .environmentObject(personaLoader)
                .environmentObject(chatRoomManager)
                .onChange(of: scenePhase) { oldValue, newValue in
                    handleScenePhaseChange(oldValue: oldValue, newValue: newValue)
                }
        }
    }
    
    // ✅ より確実なライフサイクル変更時の処理
    private func handleScenePhaseChange(oldValue: ScenePhase?, newValue: ScenePhase) {
        print("🔄 ScenePhase変更: \(oldValue?.description ?? "nil") → \(newValue.description)")
        
        switch newValue {
        case .background:
            print("🔄 アプリが背景に移行 - 即座にデータ保存")
            saveAllData()
            
        case .inactive:
            print("🔄 アプリが非アクティブに - 即座にデータ保存")
            saveAllData()
            
        case .active:
            print("🔄 アプリがアクティブに復帰")
            // アクティブ復帰時はデータを再確認
            chatViewModel.printDebugInfo()
            
        @unknown default:
            print("🔄 未知のScenePhase: \(newValue)")
            break
        }
    }
    
    // ✅ 確実なデータ保存
    private func saveAllData() {
        print("💾 全データ保存開始")
        
        // ChatViewModelの保存
        chatViewModel.saveOnAppWillTerminate()
        
        // UserDefaultsの強制同期
        UserDefaults.standard.synchronize()
        
        print("💾 全データ保存完了")
    }
}

// ✅ スプラッシュスクリーン付きメインビュー
struct MainAppWithSplashView: View {
    @State private var showingSplash = true
    @EnvironmentObject var chatViewModel: ChatViewModel
    @EnvironmentObject var personaLoader: PersonaLoader
    @EnvironmentObject var chatRoomManager: ChatRoomManager
    
    var body: some View {
        Group {
            if showingSplash {
                // ✅ スプラッシュスクリーン表示
                SplashScreenView {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        showingSplash = false
                    }
                }
            } else {
                // ✅ メインアプリ画面
                AppContentView()
                    .environmentObject(chatViewModel)
                    .environmentObject(personaLoader)
                    .environmentObject(chatRoomManager)
            }
        }
    }
}

// ✅ シンプルなスプラッシュスクリーン
struct SplashScreenView: View {
    @State private var isLoading = true
    @State private var iconScale: CGFloat = 0.8
    @State private var iconOpacity: Double = 0.0
    
    var onFinish: () -> Void
    
    var body: some View {
        ZStack {
            // 背景グラデーション
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
                
                // アプリアイコン部分
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
                        Text("また、あなたと話したい…")
                            .font(.title2)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                        
                        Text("大切な人との時間を、もう一度")
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
                        
                        Text("起動中...")
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
        // アイコンのアニメーション
        withAnimation(.easeOut(duration: 0.8)) {
            iconScale = 1.0
            iconOpacity = 1.0
        }
        
        // スプラッシュ終了（1.5秒後 - 短縮）
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.easeInOut(duration: 0.5)) {
                isLoading = false
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                onFinish()
            }
        }
    }
}

// ✅ デバッグ版AppContentView（PersonaManagerの初期化を段階的に行う）
struct AppContentView: View {
    @EnvironmentObject var chatViewModel: ChatViewModel
    @EnvironmentObject var personaLoader: PersonaLoader
    @EnvironmentObject var chatRoomManager: ChatRoomManager
    
    @State private var selectedTab: Int = 0
    @State private var isAppReady = false
    
    var body: some View {
        ZStack {
            if isAppReady {
                // ✅ アプリ準備完了後にタブビューを表示
                TabView(selection: $selectedTab) {
                    // ChatRoomListView
                    ChatRoomListView()
                        .environmentObject(chatRoomManager)
                        .environmentObject(personaLoader)
                        .environmentObject(chatViewModel)
                        .tabItem {
                            Label("チャット", systemImage: "message")
                        }
                        .tag(0)
                    
                    // ペルソナ管理
                    PersonaListView()
                        .tabItem {
                            Label("人物", systemImage: "person.2")
                        }
                        .tag(1)
                    
                    // 設定画面
                    AppSettingsView()
                        .environmentObject(chatViewModel)
                        .tabItem {
                            Label("設定", systemImage: "gear")
                        }
                        .tag(2)
                }
            } else {
                // ✅ 初期化中の画面
                VStack(spacing: 20) {
                    ProgressView()
                        .scaleEffect(1.2)
                        .tint(.blue)
                    
                    Text("アプリを準備中...")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Text("ペルソナを読み込んでいます")
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
        print("🚀 アプリ初期化開始")
        
        Task { @MainActor in
            do {
                // ✅ 段階的初期化
                print("📋 1. PersonaLoader初期化...")
                
                // PersonaLoaderの初期化を確実にする
                if !personaLoader.hasCurrentPersona {
                    print("🔧 デフォルトペルソナを設定中...")
                    personaLoader.setDefaultPersona()
                }
                
                // 少し待機
                try await Task.sleep(nanoseconds: 200_000_000) // 0.2秒
                
                print("📋 2. PersonaManager確認...")
                
                // PersonaManagerの状態を確認（直接アクセスしない）
                let personaCount = PersonaManager.shared.getPersonaCount()
                print("👥 PersonaManager ペルソナ数: \(personaCount)")
                
                // さらに少し待機
                try await Task.sleep(nanoseconds: 300_000_000) // 0.3秒
                
                print("📋 3. ChatViewModel初期化...")
                chatViewModel.printDebugInfo()
                
                // 初期化完了
                withAnimation(.easeInOut(duration: 0.5)) {
                    isAppReady = true
                }
                
                print("✅ アプリ初期化完了")
                print("🚀 現在のペルソナ: \(personaLoader.currentPersonaName)")
                
            } catch {
                print("❌ 初期化エラー: \(error)")
                
                // エラーが発生してもアプリは表示する
                withAnimation(.easeInOut(duration: 0.5)) {
                    isAppReady = true
                }
            }
        }
    }
}

// 設定画面（シンプル版）
struct AppSettingsView: View {
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @State private var showingSubscriptionView = false
    
    var body: some View {
        NavigationView {
            List {
                Section("AI機能") {
                    HStack {
                        Image(systemName: "crown.fill")
                            .foregroundColor(.yellow)
                            .font(.title2)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("サブスクリプション")
                                .font(.headline)
                            Text("AI機能の利用状況を管理")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Button("管理") {
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
                            Text("詳細設定")
                        }
                    }
                }
                
                Section("サブスクリプション状況") {
                    HStack {
                        Image(systemName: subscriptionStatusIcon)
                            .foregroundColor(subscriptionStatusColor)
                        Text("現在の状況")
                        Spacer()
                        Text(subscriptionManager.subscriptionStatus.displayName)
                            .foregroundColor(subscriptionStatusColor)
                            .fontWeight(.semibold)
                    }
                    
                    if subscriptionManager.subscriptionStatus == .trial {
                        HStack {
                            Image(systemName: "clock.fill")
                                .foregroundColor(.orange)
                            Text("トライアル期間")
                            Spacer()
                            Text("残り \(subscriptionManager.getRemainingTrialDays()) 日")
                                .foregroundColor(.orange)
                                .fontWeight(.semibold)
                        }
                    }
                }
                
                Section("アプリ情報") {
                    HStack {
                        Image(systemName: "info.circle")
                            .foregroundColor(.blue)
                        Text("バージョン")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("設定")
            .sheet(isPresented: $showingSubscriptionView) {
                SubscriptionView()
            }
        }
    }
    
    private var subscriptionStatusIcon: String {
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
    
    private var subscriptionStatusColor: Color {
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

// ✅ デバッグ用のScenePhase拡張
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
