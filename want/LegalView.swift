import SwiftUI

struct LegalView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTab = 0
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // タブ選択
                Picker("Legal Document", selection: $selectedTab) {
                    Text("利用規約").tag(0)
                    Text("プライバシーポリシー").tag(1)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                // コンテンツ表示
                TabView(selection: $selectedTab) {
                    EULAView()
                        .tag(0)
                    
                    PrivacyPolicyView()
                        .tag(1)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            }
            .navigationTitle("法的文書")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("閉じる") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct EULAView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("利用規約（EULA）")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("最終更新日: 2025年6月24日")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Group {
                    Text("1. 総則")
                        .font(.headline)
                    Text("本利用規約（以下「本規約」）は、igafactory（以下「当社」）が提供する「want」アプリケーション（以下「本アプリ」）の利用に関する条件を定めるものです。")
                    
                    Text("2. 利用の承諾")
                        .font(.headline)
                    Text("本アプリをダウンロード、インストール、または使用することにより、利用者は本規約に同意したものとみなされます。")
                    
                    Text("3. 利用可能期間")
                        .font(.headline)
                    Text("本アプリは以下の期間で利用可能です：\n• 無料トライアル期間：初回起動から3日間\n• 有料サブスクリプション期間：月額課金による継続利用")
                    
                    Text("4. 利用料金")
                        .font(.headline)
                    Text("• 無料トライアル期間中は全ての機能を無料で利用できます\n• トライアル期間終了後は、月額サブスクリプション（価格はApp Storeにて表示）が必要です\n• 課金はApp Storeを通じて行われ、Appleの課金システムに従います")
                    
                    Text("5. 禁止事項")
                        .font(.headline)
                    Text("利用者は以下の行為を行ってはなりません：\n• 本アプリの逆コンパイル、逆アセンブル、またはリバースエンジニアリング\n• 本アプリの著作権、商標権、その他の知的財産権の侵害\n• 本アプリを使用した違法行為\n• 他の利用者に迷惑をかける行為\n• 本アプリのサーバーやネットワークに負荷をかける行為")
                    
                    Text("6. プライバシー")
                        .font(.headline)
                    Text("利用者の個人情報の取り扱いについては、別途プライバシーポリシーに従います。")
                    
                    Text("7. AI機能について")
                        .font(.headline)
                    Text("本アプリはGoogle Gemini APIを使用してAI機能を提供します：\n• AIとの会話内容は適切に管理されます\n• 機密情報や個人情報の入力は避けてください\n• AIの回答は参考情報であり、医療、法律、投資等の重要な判断には使用しないでください")
                    
                    Text("8. 免責事項")
                        .font(.headline)
                    Text("• 当社は本アプリの利用により生じた損害について一切の責任を負いません\n• 本アプリの機能は予告なく変更される場合があります\n• 本アプリの利用により生じた問題について、当社は技術的サポートを提供する場合がありますが、保証するものではありません")
                    
                    Text("9. 規約の変更")
                        .font(.headline)
                    Text("当社は必要に応じて本規約を変更することができます。変更された規約は本アプリ内または当社ウェブサイトで通知されます。")
                    
                    Text("10. 準拠法・管轄裁判所")
                        .font(.headline)
                    Text("本規約の解釈および適用については、日本法に準拠し、東京地方裁判所を第一審の専属管轄裁判所とします。")
                    
                    Text("お問い合わせ")
                        .font(.headline)
                    Text("本規約に関するお問い合わせは以下までお願いします：\n• メール: igafactory2023@gmail.com")
                }
            }
            .padding()
        }
    }
}

struct PrivacyPolicyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("プライバシーポリシー")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("最終更新日: 2025年6月24日")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Group {
                    Text("1. 収集する情報")
                        .font(.headline)
                    Text("1.1 自動収集される情報\n• デバイス情報（OSバージョン、アプリバージョン等）\n• 利用統計情報（アプリの使用頻度、機能の利用状況等）\n• クラッシュレポート\n\n1.2 ユーザーが入力する情報\n• AIとの会話内容\n• 設定情報（ペルソナ設定、感情設定等）\n• サブスクリプション情報（App Storeを通じて）")
                    
                    Text("2. 情報の利用目的")
                        .font(.headline)
                    Text("収集した情報は以下の目的で利用します：\n• 本アプリの機能提供\n• サービスの改善・開発\n• カスタマーサポート\n• 不正利用の防止\n• 法的義務の履行")
                    
                    Text("3. 情報の共有")
                        .font(.headline)
                    Text("当社は以下の場合を除き、個人情報を第三者に提供しません：\n• 利用者の同意がある場合\n• 法令に基づく場合\n• 人の生命、身体、または財産の保護のために必要な場合\n• 公衆衛生の向上または児童の健全な育成の推進のために特に必要な場合")
                    
                    Text("4. 外部サービスの利用")
                        .font(.headline)
                    Text("4.1 Google Gemini API\n• AI機能の提供のために使用\n• 会話内容はGoogleのサーバーに送信されます\n• Googleのプライバシーポリシーが適用されます\n\n4.2 Apple App Store\n• アプリの配布・課金のために使用\n• Appleのプライバシーポリシーが適用されます")
                    
                    Text("5. 情報の保存期間")
                        .font(.headline)
                    Text("• 会話内容：アプリ内にローカル保存（デバイス内）\n• 設定情報：アプリ内にローカル保存\n• 利用統計：匿名化された形で永続保存")
                    
                    Text("6. 情報のセキュリティ")
                        .font(.headline)
                    Text("当社は個人情報の漏洩、滅失、き損の防止その他の個人情報の安全管理のために必要かつ適切な措置を講じます。")
                    
                    Text("7. 利用者の権利")
                        .font(.headline)
                    Text("利用者は以下の権利を有します：\n• 個人情報の開示請求\n• 個人情報の訂正・追加・削除請求\n• 個人情報の利用停止・消去請求")
                    
                    Text("8. 未成年者の情報")
                        .font(.headline)
                    Text("13歳未満の利用者からの個人情報の収集は行いません。13歳以上18歳未満の利用者については、保護者の同意を得てからサービスを提供します。")
                    
                    Text("9. プライバシーポリシーの変更")
                        .font(.headline)
                    Text("当社は必要に応じて本プライバシーポリシーを変更することができます。重要な変更がある場合は、アプリ内または当社ウェブサイトで通知します。")
                    
                    Text("10. お問い合わせ")
                        .font(.headline)
                    Text("個人情報の取り扱いに関するお問い合わせは以下までお願いします：\n\nメール: igafactory2023@gmail.com\n対応時間: 平日 9:00-18:00（日本時間）\n\nプライバシーポリシー詳細: https://tegujupe222.github.io/privacy-policy/")
                    
                    Text("11. 準拠法")
                        .font(.headline)
                    Text("本プライバシーポリシーは日本法に準拠します。")
                }
            }
            .padding()
        }
    }
}

#Preview {
    LegalView()
} 