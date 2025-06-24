import SwiftUI

struct SettingsView: View {
    @StateObject private var aiConfigManager = AIConfigManager.shared
    @StateObject private var personaManager = PersonaManager.shared
    @State private var showingAISettings = false
    @State private var showingAbout = false
    @State private var showingDataExport = false
    
    var body: some View {
        NavigationView {
            List {
                // AI設定セクション
                Section(header: Text("AI機能")) {
                    NavigationLink(destination: AISettingsView()) {
                        HStack {
                            Image(systemName: "brain.head.profile")
                                .foregroundColor(.blue)
                                .frame(width: 24)
                            
                            VStack(alignment: .leading) {
                                Text("AI設定")
                                    .font(.body)
                                
                                Text(aiConfigManager.currentConfig.isAIEnabled ? "有効" : "無効")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                
                // データ管理セクション
                Section(header: Text("データ管理")) {
                    Button(action: {
                        showingDataExport = true
                    }) {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                                .foregroundColor(.green)
                                .frame(width: 24)
                            
                            Text("データをエクスポート")
                                .foregroundColor(.primary)
                        }
                    }
                    
                    Button(action: clearAllData) {
                        HStack {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                                .frame(width: 24)
                            
                            Text("すべてのデータを削除")
                                .foregroundColor(.red)
                        }
                    }
                }
                
                // アプリ情報セクション
                Section(header: Text("アプリ情報")) {
                    HStack {
                        Image(systemName: "info.circle")
                            .foregroundColor(.blue)
                            .frame(width: 24)
                        
                        VStack(alignment: .leading) {
                            Text("バージョン")
                                .font(.body)
                            
                            Text("1.0.1")
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
                            
                            Text("このアプリについて")
                                .foregroundColor(.primary)
                        }
                    }
                }
                
                // 統計セクション
                Section(header: Text("統計")) {
                    HStack {
                        Image(systemName: "person.2")
                            .foregroundColor(.purple)
                            .frame(width: 24)
                        
                        VStack(alignment: .leading) {
                            Text("作成したペルソナ")
                                .font(.body)
                            
                            Text("\(personaManager.personas.count)人")
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
                            Text("総メッセージ数")
                                .font(.body)
                            
                            Text("計算中...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                }
                
                // サブスクリプション・法的情報セクション
                Section(header: Text("サブスクリプション・法的情報")) {
                    NavigationLink(destination: CancellationPolicyView()) {
                        HStack {
                            Image(systemName: "doc.text")
                                .foregroundColor(.blue)
                                .frame(width: 24)
                            
                            Text("キャンセルポリシー")
                                .foregroundColor(.primary)
                        }
                    }
                    
                    Button(action: {
                        // プライバシーポリシーを開く
                        if let url = URL(string: "https://tegujupe222.github.io/privacy-policy/") {
                            UIApplication.shared.open(url)
                        }
                    }) {
                        HStack {
                            Image(systemName: "hand.raised")
                                .foregroundColor(.green)
                                .frame(width: 24)
                            
                            Text("プライバシーポリシー")
                                .foregroundColor(.primary)
                        }
                    }
                    
                    Button(action: {
                        // 利用規約を開く
                        if let url = URL(string: "https://tegujupe222.github.io/privacy-policy/terms.html") {
                            UIApplication.shared.open(url)
                        }
                    }) {
                        HStack {
                            Image(systemName: "doc.plaintext")
                                .foregroundColor(.orange)
                                .frame(width: 24)
                            
                            Text("利用規約")
                                .foregroundColor(.primary)
                        }
                    }
                }
            }
            .navigationTitle("設定")
        }
        .sheet(isPresented: $showingAbout) {
            AboutView()
        }
        .actionSheet(isPresented: $showingDataExport) {
            ActionSheet(
                title: Text("データをエクスポート"),
                message: Text("どのデータをエクスポートしますか？"),
                buttons: [
                    .default(Text("ペルソナデータ")) {
                        exportPersonaData()
                    },
                    .default(Text("会話履歴")) {
                        exportConversationData()
                    },
                    .default(Text("すべて")) {
                        exportAllData()
                    },
                    .cancel()
                ]
            )
        }
    }
    
    // MARK: - Private Methods
    
    private func clearAllData() {
        // 確認アラートを表示する実装が必要
        personaManager.personas.removeAll()
        aiConfigManager.resetToDefaults()
    }
    
    private func exportPersonaData() {
        // ペルソナデータのエクスポート実装
        print("ペルソナデータをエクスポート")
    }
    
    private func exportConversationData() {
        // 会話履歴のエクスポート実装
        print("会話履歴をエクスポート")
    }
    
    private func exportAllData() {
        // すべてのデータのエクスポート実装
        print("すべてのデータをエクスポート")
    }
}

// MARK: - About View

struct AboutView: View {
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // アプリアイコン
                    Image(systemName: "bubble.left.and.bubble.right.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.blue)
                    
                    // アプリ名
                    Text("want")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    // バージョン
                    Text("Version 1.0.1")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    // 説明
                    VStack(spacing: 16) {
                        Text("wantは、あなただけの特別な人物と会話を楽しめるアプリです。")
                            .multilineTextAlignment(.center)
                        
                        Text("家族、友人、恋人、様々な関係性の人物を作成して、それぞれの個性を持った会話を体験できます。")
                            .multilineTextAlignment(.center)
                    }
                    .font(.body)
                    .foregroundColor(.primary)
                    
                    // 機能紹介
                    VStack(alignment: .leading, spacing: 12) {
                        SettingsFeatureRow(
                            icon: "person.crop.circle.badge.plus",
                            title: "ペルソナ作成",
                            description: "自由にキャラクターを作成"
                        )
                        
                        SettingsFeatureRow(
                            icon: "brain.head.profile",
                            title: "AI会話",
                            description: "自然で人間らしい対話"
                        )
                        
                        SettingsFeatureRow(
                            icon: "heart.fill",
                            title: "感情表現",
                            description: "豊かな感情の交流"
                        )
                        
                        SettingsFeatureRow(
                            icon: "lock.shield",
                            title: "プライバシー保護",
                            description: "あなたのデータを安全に保護"
                        )
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("このアプリについて")
            .navigationBarItems(
                trailing: Button("完了") {
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
                    // ヘッダー
                    VStack(spacing: 16) {
                        Image(systemName: "doc.text")
                            .font(.system(size: 60))
                            .foregroundColor(.blue)
                        
                        Text("キャンセルポリシー")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("サブスクリプションのキャンセルについて\n詳しくご説明いたします")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    
                    // キャンセル方法
                    VStack(spacing: 16) {
                        Text("キャンセル方法")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            CancellationStepRow(
                                number: "1",
                                title: "iPhoneの「設定」アプリを開く",
                                description: "ホーム画面から設定アプリをタップしてください"
                            )
                            
                            CancellationStepRow(
                                number: "2",
                                title: "Apple IDをタップ",
                                description: "画面最上部に表示されているApple IDをタップしてください"
                            )
                            
                            CancellationStepRow(
                                number: "3",
                                title: "「サブスクリプション」を選択",
                                description: "Apple IDの設定画面から「サブスクリプション」をタップしてください"
                            )
                            
                            CancellationStepRow(
                                number: "4",
                                title: "「want」を選択してキャンセル",
                                description: "サブスクリプション一覧から「want」を選択し、「キャンセル」をタップしてください"
                            )
                            
                            CancellationStepRow(
                                number: "5",
                                title: "代替方法：App Storeから",
                                description: "App Store → アカウント → サブスクリプションからも可能です"
                            )
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                    
                    // キャンセル後の利用について
                    VStack(spacing: 16) {
                        Text("キャンセル後の利用について")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            PolicyRow(
                                icon: "checkmark.circle.fill",
                                title: "期間終了まで利用可能",
                                description: "キャンセル後も、既に支払い済みの期間中は全ての機能をご利用いただけます"
                            )
                            
                            PolicyRow(
                                icon: "xmark.circle.fill",
                                title: "自動更新は停止",
                                description: "期間終了後は自動的に更新されず、AI機能は制限されます"
                            )
                            
                            PolicyRow(
                                icon: "arrow.clockwise",
                                title: "いつでも再開可能",
                                description: "期間終了後も、いつでもサブスクリプションを再開できます"
                            )
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                    
                    // 返金について
                    VStack(spacing: 16) {
                        Text("返金について")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            PolicyRow(
                                icon: "dollarsign.circle.fill",
                                title: "返金対象",
                                description: "期間終了後の自動更新分のみ返金対象となります"
                            )
                            
                            PolicyRow(
                                icon: "clock.fill",
                                title: "返金申請期間",
                                description: "返金申請は購入後90日以内に限ります"
                            )
                            
                            PolicyRow(
                                icon: "questionmark.circle.fill",
                                title: "返金方法",
                                description: "返金はApp Storeの返金ポリシーに従います。詳細はApp Storeのサポートにお問い合わせください"
                            )
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                    
                    // お問い合わせ
                    VStack(spacing: 16) {
                        Text("お問い合わせ")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("• サブスクリプションに関するお問い合わせは、App Storeのサポートをご利用ください")
                            Text("• アプリの機能に関するお問い合わせは、開発者までお気軽にお声かけください")
                            Text("• 返金に関する詳細は、Appleの公式ガイドラインをご確認ください")
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
            .navigationTitle("キャンセルポリシー")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                trailing: Button("完了") {
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
