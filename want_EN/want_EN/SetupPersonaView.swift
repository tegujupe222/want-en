import SwiftUI

struct SetupPersonaView: View {
    @StateObject private var personaManager = PersonaManager.shared
    @Environment(\.dismiss) private var dismiss
    
    // オプショナルなコールバック関数
    let onComplete: ((UserPersona) -> Void)?
    let editingPersona: UserPersona?
    
    @State private var setupMode: SetupMode = .selection
    @State private var showingFileImport = false
    
    // フォーム用の状態変数
    @State private var name: String = ""
    @State private var relationship: String = ""
    @State private var selectedPersonality: Set<String> = []
    @State private var speechStyle: String = ""
    @State private var catchphrases: String = ""
    @State private var favoriteTopics: String = ""
    @State private var selectedMood: PersonaMood = .happy
    @State private var selectedEmoji: String = "😊"
    @State private var selectedAvatarImage: UIImage?  // ✅ 選択された画像
    @State private var avatarImageFileName: String?   // ✅ 保存された画像ファイル名
    @State private var selectedColor: Color = .blue
    @State private var currentStep: Int = 0
    @State private var showingRelationshipPicker = false
    
    // ✅ キーボード非表示用
    @FocusState private var isTextFieldFocused: Bool
    
    private let personalityOptions = [
        "優しい", "思いやりがある", "聞き上手", "明るい", "ユーモアがある",
        "真面目", "冷静", "情熱的", "創造的", "知的", "親しみやすい"
    ]
    
    private let relationshipOptions = [
        "家族", "友人", "恋人", "先生", "同僚", "先輩", "後輩", "大切な人"
    ]
    
    private let speechStyleOptions = [
        "丁寧で暖かい口調", "親しみやすい口調", "フレンドリーな口調",
        "落ち着いた口調", "元気で明るい口調", "優しく包み込む口調"
    ]
    
    enum SetupMode {
        case selection
        case manual
        case automatic
    }
    
    // 複数のイニシャライザーを提供
    init() {
        self.onComplete = nil
        self.editingPersona = nil
    }
    
    init(onComplete: @escaping (UserPersona) -> Void) {
        self.onComplete = onComplete
        self.editingPersona = nil
    }
    
    init(editingPersona: UserPersona) {
        self.onComplete = nil
        self.editingPersona = editingPersona
        
        // 編集モードの場合は初期値を設定
        self._name = State(initialValue: editingPersona.name)
        self._relationship = State(initialValue: editingPersona.relationship)
        self._selectedPersonality = State(initialValue: Set(editingPersona.personality))
        self._speechStyle = State(initialValue: editingPersona.speechStyle)
        self._catchphrases = State(initialValue: editingPersona.catchphrases.joined(separator: ", "))
        self._favoriteTopics = State(initialValue: editingPersona.favoriteTopics.joined(separator: ", "))
        self._selectedMood = State(initialValue: editingPersona.mood)
        self._selectedEmoji = State(initialValue: editingPersona.customization.avatarEmoji ?? "😊")
        self._avatarImageFileName = State(initialValue: editingPersona.customization.avatarImageFileName)  // ✅ 画像ファイル名を初期化
        self._selectedColor = State(initialValue: editingPersona.customization.avatarColor)
        self._setupMode = State(initialValue: .manual)
        self._currentStep = State(initialValue: 5)
    }
    
    var body: some View {
        // NavigationViewの重複を避けるため、条件付きで使用
        Group {
            if editingPersona != nil {
                // 編集モードの場合はNavigationViewを使わない
                mainContent
            } else {
                // 新規作成の場合のみNavigationViewを使用
                NavigationView {
                    mainContent
                }
            }
        }
        .onAppear {
            // 編集モードの場合は手動設定モードに切り替え
            if editingPersona != nil {
                setupMode = .manual
            }
        }
    }
    
    private var mainContent: some View {
        VStack(spacing: 0) {
            // プログレスバー（手動設定時のみ）
            if setupMode == .manual {
                ProgressView(value: Double(currentStep), total: 5.0)
                    .progressViewStyle(LinearProgressViewStyle())
                    .padding()
            }
            
            // メインコンテンツ
            Group {
                switch setupMode {
                case .selection:
                    if editingPersona != nil {
                        // 編集モードの場合は直接手動設定へ
                        manualSetupView
                    } else {
                        setupModeSelectionView
                    }
                case .manual:
                    manualSetupView
                case .automatic:
                    automaticSetupView
                }
            }
            
            // ナビゲーションボタン（手動設定時のみ）
            if setupMode == .manual {
                navigationButtons
            }
        }
        .navigationTitle(editingPersona != nil ? "プロフィール編集" :
                       setupMode == .selection ? "設定方法を選択" : "話したい相手を設定")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("キャンセル") {
                    dismiss()
                }
            }
        }
        // ✅ 改善されたキーボード非表示対応
        .simultaneousGesture(
            TapGesture()
                .onEnded { _ in
                    hideKeyboard()
                }
        )
    }
    
    // ✅ キーボード非表示用メソッド
    private func hideKeyboard() {
        isTextFieldFocused = false
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    private var setupModeSelectionView: some View {
        VStack(spacing: 32) {
            // ヘッダー
            VStack(spacing: 16) {
                Image(systemName: "person.badge.plus")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                
                Text("設定方法を選択してください")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("手動で設定するか、\n簡単設定から始められます")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            // 設定方法の選択肢
            VStack(spacing: 16) {
                // ✅ 簡単設定ボタン - レスポンシブ改善
                Button(action: {
                    setupMode = .automatic
                }) {
                    SetupOptionCard(
                        icon: "magic.wand",
                        title: "簡単設定（推奨）",
                        description: "基本的な情報のみで\nすぐに始められます",
                        badge: "簡単",
                        isRecommended: true
                    )
                }
                
                // ✅ 手動設定ボタン - レスポンシブ改善
                Button(action: {
                    setupMode = .manual
                }) {
                    SetupOptionCard(
                        icon: "hand.raised",
                        title: "詳細設定",
                        description: "相手の特徴や話し方を\n詳しく設定できます",
                        badge: "詳細",
                        isRecommended: false
                    )
                }
            }
            
            Spacer()
        }
        .padding()
    }
    
    private var automaticSetupView: some View {
        ScrollView {
            VStack(spacing: 32) {
                // ヘッダー
                VStack(spacing: 16) {
                    Image(systemName: "magic.wand")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                    
                    Text("簡単設定")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("基本的な情報を入力するだけで\nすぐに会話を始められます")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                // 簡単フォーム
                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("お相手の名前")
                            .font(.headline)
                        TextField("例: お母さん、田中さん、友達", text: $name)
                            .textFieldStyle(.roundedBorder)
                            .focused($isTextFieldFocused)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("関係性")
                            .font(.headline)
                        
                        // ✅ 改善されたピッカー
                        Button(action: {
                            showingRelationshipPicker = true
                        }) {
                            HStack {
                                Text(relationship.isEmpty ? "選択してください" : relationship)
                                    .foregroundColor(relationship.isEmpty ? .secondary : .primary)
                                    .font(.body)
                                Spacer()
                                Image(systemName: "chevron.down")
                                    .foregroundColor(.secondary)
                                    .font(.system(size: 12))
                            }
                            .padding(.vertical, 12)
                            .padding(.horizontal, 16)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                        }
                        .confirmationDialog("関係性を選択", isPresented: $showingRelationshipPicker) {
                            ForEach(relationshipOptions, id: \.self) { option in
                                Button(option) {
                                    relationship = option
                                    applyQuickSettings()
                                }
                            }
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                // 作成ボタン
                Button(action: {
                    savePersona()
                }) {
                    Text("ペルソナを作成")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(name.isEmpty || relationship.isEmpty ? Color.gray : Color.blue)
                        .cornerRadius(12)
                }
                .disabled(name.isEmpty || relationship.isEmpty)
                
                Spacer()
            }
            .padding()
        }
    }
    
    private var manualSetupView: some View {
        TabView(selection: $currentStep) {
            // ステップ1: 基本情報
            stepOneView.tag(0)
            
            // ステップ2: 関係性と性格
            stepTwoView.tag(1)
            
            // ステップ3: 話し方
            stepThreeView.tag(2)
            
            // ステップ4: 話題と口癖
            stepFourView.tag(3)
            
            // ステップ5: 外見設定
            stepFiveView.tag(4)
            
            // ステップ6: 確認
            confirmationView.tag(5)
        }
        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
    }
    
    private var navigationButtons: some View {
        HStack {
            if currentStep > 0 {
                Button(action: {
                    currentStep -= 1
                }) {
                    Text("戻る")
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(.blue)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                }
            }
            
            Spacer()
            
            Button(action: {
                if currentStep == 5 {
                    savePersona()
                } else {
                    currentStep += 1
                }
            }) {
                Text(currentStep == 5 ? "完了" : "次へ")
                    .font(.body)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(canProceed ? Color.blue : Color.gray)
                    .cornerRadius(8)
            }
            .disabled(!canProceed)
        }
        .padding()
    }
    
    private var stepOneView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("話したい相手の名前を教えてください")
                        .font(.headline)
                    
                    TextField("例: お父さん、田中さん、大切な人", text: $name)
                        .textFieldStyle(.roundedBorder)
                        .focused($isTextFieldFocused)
                }
                
                Spacer()
            }
            .padding()
        }
    }
    
    private var stepTwoView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 16) {
                    Text("どんな関係の方ですか？")
                        .font(.headline)
                    
                    // ✅ 改善されたグリッドレイアウト
                    VStack(spacing: 8) {
                        ForEach(Array(relationshipOptions.chunked(into: 2)), id: \.self) { row in
                            HStack(spacing: 8) {
                                ForEach(row, id: \.self) { option in
                                    Button(action: {
                                        relationship = option
                                    }) {
                                        Text(option)
                                            .font(.body)
                                            .fontWeight(.medium)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 12)
                                            .padding(.horizontal, 8)
                                            .background(relationship == option ? Color.accentColor : Color(.systemGray6))
                                            .foregroundColor(relationship == option ? .white : .primary)
                                            .cornerRadius(8)
                                    }
                                }
                                
                                // 奇数個の場合の調整
                                if row.count == 1 {
                                    Spacer()
                                        .frame(maxWidth: .infinity)
                                }
                            }
                        }
                    }
                }
                
                VStack(alignment: .leading, spacing: 16) {
                    Text("どんな性格の方ですか？（複数選択可）")
                        .font(.headline)
                    
                    // ✅ 改善されたグリッドレイアウト
                    VStack(spacing: 8) {
                        ForEach(Array(personalityOptions.chunked(into: 2)), id: \.self) { row in
                            HStack(spacing: 8) {
                                ForEach(row, id: \.self) { option in
                                    Button(action: {
                                        if selectedPersonality.contains(option) {
                                            selectedPersonality.remove(option)
                                        } else {
                                            selectedPersonality.insert(option)
                                        }
                                    }) {
                                        Text(option)
                                            .font(.body)
                                            .fontWeight(.medium)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 12)
                                            .padding(.horizontal, 8)
                                            .background(selectedPersonality.contains(option) ? Color.accentColor : Color(.systemGray6))
                                            .foregroundColor(selectedPersonality.contains(option) ? .white : .primary)
                                            .cornerRadius(8)
                                    }
                                }
                                
                                // 奇数個の場合の調整
                                if row.count == 1 {
                                    Spacer()
                                        .frame(maxWidth: .infinity)
                                }
                            }
                        }
                    }
                }
                
                Spacer()
            }
            .padding()
        }
    }
    
    private var stepThreeView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 16) {
                    Text("どんな話し方をする方ですか？")
                        .font(.headline)
                    
                    VStack(spacing: 8) {
                        ForEach(speechStyleOptions, id: \.self) { option in
                            Button(action: {
                                speechStyle = option
                            }) {
                                HStack {
                                    Text(option)
                                        .font(.body)
                                        .fontWeight(.medium)
                                        .foregroundColor(speechStyle == option ? .white : .primary)
                                    Spacer()
                                    if speechStyle == option {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(.white)
                                            .font(.system(size: 16, weight: .bold))
                                    }
                                }
                                .padding(.vertical, 16)
                                .padding(.horizontal, 16)
                                .background(speechStyle == option ? Color.accentColor : Color(.systemGray6))
                                .cornerRadius(12)
                            }
                        }
                    }
                }
                
                Spacer()
            }
            .padding()
        }
    }
    
    private var stepFourView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("よく使っていた口癖はありますか？")
                        .font(.headline)
                    
                    TextField("例: そうだね、なるほど、大丈夫だよ（カンマ区切り）", text: $catchphrases)
                        .textFieldStyle(.roundedBorder)
                        .focused($isTextFieldFocused)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("よく話していた話題は何ですか？")
                        .font(.headline)
                    
                    TextField("例: 仕事、趣味、家族、思い出話（カンマ区切り）", text: $favoriteTopics)
                        .textFieldStyle(.roundedBorder)
                        .focused($isTextFieldFocused)
                }
                
                Spacer()
            }
            .padding()
        }
    }
    
    private var stepFiveView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("外見を設定してください")
                    .font(.headline)
                
                // ✅ 画像選択セクション
                ImageOptionsView(
                    selectedImage: $selectedAvatarImage,
                    avatarEmoji: $selectedEmoji,
                    showingImagePicker: .constant(false),
                    onImageSelected: { image in
                        selectedAvatarImage = image
                        selectedEmoji = "" // 画像を選択したら絵文字をクリア
                    },
                    onEmojiSelected: {
                        selectedAvatarImage = nil
                        avatarImageFileName = nil
                        if selectedEmoji.isEmpty {
                            selectedEmoji = "😊"
                        }
                    },
                    onRemoveImage: {
                        selectedAvatarImage = nil
                        avatarImageFileName = nil
                    }
                )
                
                VStack(spacing: 20) {
                    // アバター絵文字（画像が選択されていない場合のみ表示）
                    if selectedAvatarImage == nil {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("アバター絵文字")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            
                            TextField("😊", text: $selectedEmoji)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 100)
                                .focused($isTextFieldFocused)
                        }
                    }
                    
                    // カラー選択
                    VStack(alignment: .leading, spacing: 8) {
                        Text("カラーテーマ")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        
                        ColorPicker("カラーを選択", selection: $selectedColor)
                            .labelsHidden()
                    }
                    
                    // 気分設定
                    VStack(alignment: .leading, spacing: 8) {
                        Text("基本的な気分")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        
                        Picker("気分", selection: $selectedMood) {
                            ForEach(PersonaMood.allCases, id: \.self) { mood in
                                HStack {
                                    Text(mood.emoji)
                                    Text(mood.displayName)
                                }
                                .tag(mood)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                    }
                    
                    // プレビュー
                    VStack(spacing: 8) {
                        Text("プレビュー")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        
                        // ✅ 画像対応のプレビュー
                        if let avatarImage = selectedAvatarImage {
                            Image(uiImage: avatarImage)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 80, height: 80)
                                .clipShape(Circle())
                                .overlay(
                                    Circle()
                                        .stroke(selectedColor.opacity(0.3), lineWidth: 2)
                                )
                        } else {
                            AvatarView(
                                name: name.isEmpty ? "名前" : name,
                                emoji: selectedEmoji.isEmpty ? nil : selectedEmoji,
                                color: selectedColor,
                                size: 80
                            )
                        }
                    }
                }
                
                Spacer()
            }
            .padding()
        }
    }
    
    private var confirmationView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("設定内容を確認してください")
                    .font(.headline)
                
                VStack(alignment: .leading, spacing: 12) {
                    InfoRow(label: "名前", value: name)
                    InfoRow(label: "関係", value: relationship)
                    InfoRow(label: "性格", value: Array(selectedPersonality).joined(separator: ", "))
                    InfoRow(label: "話し方", value: speechStyle)
                    InfoRow(label: "気分", value: selectedMood.displayName)
                    
                    if !catchphrases.isEmpty {
                        InfoRow(label: "口癖", value: catchphrases)
                    }
                    
                    if !favoriteTopics.isEmpty {
                        InfoRow(label: "話題", value: favoriteTopics)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                Text("この設定で「\(name)」との会話を始めます。いつでも設定は変更できます。")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top)
            }
            .padding()
        }
    }
    
    private var canProceed: Bool {
        switch currentStep {
        case 0: return !name.isEmpty
        case 1: return !relationship.isEmpty && !selectedPersonality.isEmpty
        case 2: return !speechStyle.isEmpty
        case 3, 4, 5: return true
        default: return false
        }
    }
    
    private func applyQuickSettings() {
        // 関係性に基づいたデフォルト設定を適用
        switch relationship {
        case "家族":
            selectedPersonality = Set(["優しい", "思いやりがある"])
            speechStyle = "丁寧で暖かい口調"
            catchphrases = "大丈夫よ, お疲れさま"
            favoriteTopics = "日常の出来事, 健康, 家族のこと"
            selectedEmoji = "👨‍👩‍👧‍👦"
            selectedColor = Color.personaPink  // 安全な色を使用
            
        case "友人":
            selectedPersonality = Set(["明るい", "親しみやすい"])
            speechStyle = "親しみやすい口調"
            catchphrases = "そうだね, すごいじゃん"
            favoriteTopics = "趣味, エンタメ, 日常会話"
            selectedEmoji = "😊"
            selectedColor = Color.personaLightBlue  // 安全な色を使用
            
        case "恋人":
            selectedPersonality = Set(["優しい", "愛情深い"])
            speechStyle = "優しく包み込む口調"
            catchphrases = "愛してる, 大丈夫だよ"
            favoriteTopics = "思い出話, 将来のこと, 愛情表現"
            selectedEmoji = "💕"
            selectedColor = Color.personaPink  // 安全な色を使用
            
        default:
            selectedPersonality = Set(["親しみやすい"])
            speechStyle = "親しみやすい口調"
            catchphrases = "よろしく"
            favoriteTopics = "日常会話"
            selectedEmoji = "😊"
            selectedColor = .blue  // 標準の青は安全
        }
    }
    
    private func savePersona() {
        let personality = selectedPersonality.isEmpty ? ["親しみやすい"] : Array(selectedPersonality)
        let catchphrasesArray = catchphrases.isEmpty ? ["よろしく"] :
            catchphrases.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        let topicsArray = favoriteTopics.isEmpty ? ["日常会話"] :
            favoriteTopics.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        
        let persona: UserPersona
        
        // 編集モードの場合は既存のペルソナを更新
        if let editing = editingPersona {
            // ✅ 画像保存処理
            var finalImageFileName = avatarImageFileName
            if let selectedImage = selectedAvatarImage {
                finalImageFileName = ImageManager.shared.saveAvatarImage(selectedImage, for: editing.id)
                
                // 古い画像ファイルがあれば削除
                if let oldImageFileName = editing.customization.avatarImageFileName,
                   oldImageFileName != finalImageFileName {
                    ImageManager.shared.deleteAvatarImage(fileName: oldImageFileName)
                }
            }
            
            var customization = PersonaCustomization(
                avatarEmoji: selectedAvatarImage == nil ? (selectedEmoji.isEmpty ? nil : selectedEmoji) : nil,
                avatarImageFileName: finalImageFileName,
                avatarColor: selectedColor
            )
            
            // 安全性チェック
            customization.makeSafe()
            
            persona = UserPersona(
                id: editing.id,
                name: name,
                relationship: relationship,
                personality: personality,
                speechStyle: speechStyle.isEmpty ? "親しみやすい口調" : speechStyle,
                catchphrases: catchphrasesArray,
                favoriteTopics: topicsArray,
                mood: selectedMood,
                customization: customization
            )
            personaManager.updatePersona(persona)
        } else {
            // 新規作成の場合
            let newPersonaId = UUID().uuidString
            
            // ✅ 画像保存処理
            var finalImageFileName: String?
            var finalEmoji = selectedEmoji.isEmpty ? nil : selectedEmoji
            
            if let selectedImage = selectedAvatarImage {
                finalImageFileName = ImageManager.shared.saveAvatarImage(selectedImage, for: newPersonaId)
                finalEmoji = nil // 画像がある場合は絵文字をクリア
            }
            
            var customization = PersonaCustomization(
                avatarEmoji: finalEmoji,
                avatarImageFileName: finalImageFileName,
                avatarColor: selectedColor
            )
            
            // 安全性チェック
            customization.makeSafe()
            
            persona = UserPersona(
                id: newPersonaId,
                name: name,
                relationship: relationship,
                personality: personality,
                speechStyle: speechStyle.isEmpty ? "親しみやすい口調" : speechStyle,
                catchphrases: catchphrasesArray,
                favoriteTopics: topicsArray,
                mood: selectedMood,
                customization: customization
            )
            
            personaManager.addPersona(persona)
        }
        
        // コールバック呼び出し
        onComplete?(persona)
        
        dismiss()
    }
}

// ✅ 改善されたSetupOptionCard
struct SetupOptionCard: View {
    let icon: String
    let title: String
    let description: String
    let badge: String
    let isRecommended: Bool
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: icon)
                    .font(.title)
                    .foregroundColor(.blue)
                    .frame(width: 50)
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(title)
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        if isRecommended {
                            Text(badge)
                                .font(.caption)
                                .fontWeight(.semibold)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color.green)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        } else {
                            Text(badge)
                                .font(.caption)
                                .fontWeight(.semibold)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color.blue.opacity(0.2))
                                .foregroundColor(.blue)
                                .cornerRadius(8)
                        }
                    }
                    
                    Text(description)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isRecommended ? Color.green.opacity(0.3) : Color.clear, lineWidth: 2)
        )
    }
}

struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value.isEmpty ? "未設定" : value)
                .font(.body)
        }
    }
}

// ✅ 配列のチャンク化用エクステンション
extension Array {
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}

// AvatarViewは別ファイルで定義済み

#Preview {
    SetupPersonaView()
}
