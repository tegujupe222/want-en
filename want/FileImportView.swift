import SwiftUI
import UniformTypeIdentifiers

struct FileImportView: View {
    @StateObject private var lineAnalyzer = LineAnalyzer()
    @Binding var isPresented: Bool
    let onAnalysisComplete: (AnalysisResult) -> Void
    
    @State private var showingFilePicker = false
    @State private var showingInstructions = false
    @State private var dragOver = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                if lineAnalyzer.isAnalyzing {
                    analysisProgressView
                } else if let result = lineAnalyzer.analysisResult {
                    analysisResultView(result)
                } else {
                    importOptionsView
                }
            }
            .padding()
            .navigationTitle("トーク履歴をインポート")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        isPresented = false
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("使い方") {
                        showingInstructions = true
                    }
                }
            }
            .sheet(isPresented: $showingInstructions) {
                InstructionsView()
            }
            .fileImporter(
                isPresented: $showingFilePicker,
                allowedContentTypes: [.plainText, .text],
                allowsMultipleSelection: false
            ) { result in
                handleFileImport(result)
            }
            .alert("エラー", isPresented: .constant(lineAnalyzer.errorMessage != nil)) {
                Button("OK") {
                    lineAnalyzer.errorMessage = nil
                }
            } message: {
                Text(lineAnalyzer.errorMessage ?? "")
            }
        }
    }
    
    private var importOptionsView: some View {
        VStack(spacing: 32) {
            // ヘッダー
            VStack(spacing: 16) {
                Image(systemName: "doc.text.magnifyingglass")
                    .font(.system(size: 60))
                    .foregroundColor(.accentColor)
                
                Text("LINEトーク履歴を分析")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("トーク履歴から相手の話し方や\n性格を自動で分析します")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            // インポートボタン
            VStack(spacing: 16) {
                importButton
                
                // ドラッグ&ドロップエリア
                dropArea
            }
            
            Spacer()
        }
    }
    
    private var importButton: some View {
        Button(action: {
            showingFilePicker = true
        }) {
            Text("ファイルを選択")
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.accentColor)
                .cornerRadius(12)
        }
    }
    
    private var dropArea: some View {
        VStack {
            Image(systemName: "icloud.and.arrow.down")
                .font(.largeTitle)
                .padding(.bottom, 8)
            Text("ここにファイルをドラッグ＆ドロップ")
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(dragOver ? Color.accentColor.opacity(0.2) : Color(.systemGray).opacity(0.1))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(
                    dragOver ? Color.accentColor : Color(.systemGray).opacity(0.5),
                    style: StrokeStyle(lineWidth: 2, dash: [8])
                )
        )
        .onDrop(of: [.plainText], isTargeted: $dragOver) { providers in
            handleDroppedFiles(providers)
        }
    }
    
    private var analysisProgressView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // プログレスアニメーション
            VStack(spacing: 16) {
                loadingIndicator
                
                Text("トーク履歴を分析中...")
                    .font(.headline)
                
                Text("話し方や性格の特徴を\n自動で抽出しています")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
        }
    }
    
    private var loadingIndicator: some View {
        ZStack {
            Circle()
                .stroke(Color(.systemGray).opacity(0.3), lineWidth: 8)
            
            Circle()
                .trim(from: 0, to: lineAnalyzer.analysisProgress)
                .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.linear, value: lineAnalyzer.analysisProgress)
            
            Text("\(Int(lineAnalyzer.analysisProgress * 100))%")
                .font(.headline)
                .fontWeight(.bold)
        }
        .frame(width: 80, height: 80)
    }
    
    private func analysisResultView(_ result: AnalysisResult) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // ヘッダー
                VStack(spacing: 8) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.title2)
                        Text("分析完了！")
                            .font(.title2)
                            .fontWeight(.bold)
                    }
                    
                    Text("以下の特徴が検出されました")
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.bottom)
                
                // 分析結果
                VStack(alignment: .leading, spacing: 16) {
                    ResultCard(
                        title: "検出された名前",
                        content: result.detectedName,
                        icon: "person.circle"
                    )
                    
                    ResultCard(
                        title: "話し方の特徴",
                        content: result.communicationStyle,
                        icon: "bubble.left"
                    )
                    
                    ResultCard(
                        title: "性格",
                        content: result.personality.joined(separator: ", "),
                        icon: "heart"
                    )
                    
                    ResultCard(
                        title: "よく使うフレーズ",
                        content: result.commonPhrases.prefix(5).joined(separator: ", "),
                        icon: "quote.bubble"
                    )
                    
                    ResultCard(
                        title: "話題",
                        content: result.favoriteTopics.joined(separator: ", "),
                        icon: "bubble.left.and.bubble.right"
                    )
                    
                    ResultCard(
                        title: "関係性",
                        content: result.messageFrequency,
                        icon: "person.2"
                    )
                }
                
                // 適用ボタン
                importSuccessButton(result)
            }
            .padding()
        }
    }
    
    private func importSuccessButton(_ result: AnalysisResult) -> some View {
                Button(action: {
                    onAnalysisComplete(result)
                    isPresented = false
                }) {
                        Text("この設定を適用")
                .font(.headline)
                            .fontWeight(.semibold)
                .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                .background(Color.accentColor)
                    .cornerRadius(12)
                }
                .padding(.top)
    }
    
    private func handleFileImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            
            do {
                let content = try String(contentsOf: url, encoding: .utf8)
                lineAnalyzer.analyzeLineHistory(fileContent: content)
            } catch {
                lineAnalyzer.errorMessage = "ファイルの読み込みに失敗しました: \(error.localizedDescription)"
            }
            
        case .failure(let error):
            lineAnalyzer.errorMessage = "ファイルの選択に失敗しました: \(error.localizedDescription)"
        }
    }
    
    private func handleDroppedFiles(_ providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first else { return false }
        
        if provider.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) {
            provider.loadItem(forTypeIdentifier: UTType.plainText.identifier, options: nil) { data, error in
                DispatchQueue.main.async {
                    if let data = data as? Data,
                       let content = String(data: data, encoding: .utf8) {
                        lineAnalyzer.analyzeLineHistory(fileContent: content)
                    }
                }
            }
            return true
        }
        
        return false
    }
}

struct ResultCard: View {
    let title: String
    let content: String
    let icon: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.accentColor)
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            
            Text(content.isEmpty ? "検出されませんでした" : content)
                .font(.body)
                .foregroundColor(content.isEmpty ? .secondary : .primary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct InstructionsView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // LINEエクスポート手順
                    InstructionSection(
                        title: "LINEトーク履歴のエクスポート方法",
                        icon: "1.circle.fill",
                        steps: [
                            "LINEアプリで対象のトークルームを開く",
                            "右上のメニュー（☰）をタップ",
                            "「その他」→「トーク履歴を送信」を選択",
                            "「テキストファイル」を選択",
                            "「ファイルに保存」でファイルを保存"
                        ]
                    )
                    
                    Divider()
                    
                    // 注意事項
                    InstructionSection(
                        title: "注意事項",
                        icon: "exclamationmark.triangle.fill",
                        steps: [
                            "プライバシー保護のため、分析はデバイス内で実行されます",
                            "ファイルは分析後に自動で削除されます",
                            "個人情報は外部に送信されません",
                            "大きなファイルは分析に時間がかかる場合があります"
                        ]
                    )
                    
                    Divider()
                    
                    // 分析内容
                    InstructionSection(
                        title: "分析される内容",
                        icon: "chart.bar.fill",
                        steps: [
                            "話し方の特徴（敬語使用率、絵文字頻度など）",
                            "よく使うフレーズや口癖",
                            "性格の傾向（優しさ、明るさなど）",
                            "よく話す話題",
                            "コミュニケーションの頻度"
                        ]
                    )
                }
                .padding()
            }
            .navigationTitle("使い方")
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

struct InstructionSection: View {
    let title: String
    let icon: String
    let steps: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.accentColor)
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                    HStack(alignment: .top, spacing: 8) {
                        Text("\(index + 1).")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(width: 20, alignment: .leading)
                        
                        Text(step)
                            .font(.body)
                    }
                }
            }
        }
    }
}

#Preview {
    FileImportView(isPresented: .constant(true)) { result in
        print("Analysis result: \(result)")
    }
}
