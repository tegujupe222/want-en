import SwiftUI

struct AIView: View {
    @StateObject private var personaManager = PersonaManager.shared
    @State private var selectedPersona: UserPersona?
    @State private var showingChat = false
    @State private var showingPersonaDetail = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // ヘッダー
                headerView
                
                if personaManager.personas.isEmpty {
                    // 空の状態
                    emptyStateView
                } else {
                    // ペルソナ選択リスト
                    personaListView
                }
                
                Spacer()
            }
            .navigationBarHidden(true)
        }
        .fullScreenCover(isPresented: $showingChat) {
            if let persona = selectedPersona {
                ChatView(isAIMode: true, persona: persona)
            }
        }
        .sheet(isPresented: $showingPersonaDetail) {
            if let persona = selectedPersona {
                PersonaDetailView(persona: persona)
            }
        }
    }
    
    // MARK: - Header View
    
    private var headerView: some View {
        VStack(spacing: 16) {
            // タイトル
            HStack {
                Text("AI チャット")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Spacer()
                
                // 設定ボタン
                NavigationLink(destination: AISettingsView()) {
                    Image(systemName: "gearshape.fill")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
            }
            
            // サブタイトル
            Text("話したいペルソナを選択してください")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }
    
    // MARK: - Empty State View
    
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "person.crop.circle.badge.plus")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            VStack(spacing: 8) {
                Text("まだペルソナがありません")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text("「人物」タブでペルソナを作成すると\nAIチャットを楽しめます")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            // 人物タブへの誘導ボタン
            Button(action: {
                // TabViewで人物タブに切り替える処理が必要
                // 現在の実装では直接制御できないため、メッセージのみ表示
            }) {
                HStack {
                    Image(systemName: "person.fill")
                    Text("ペルソナを作成する")
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(Color.blue)
                .cornerRadius(25)
            }
            
            Spacer()
        }
        .padding(.horizontal)
    }
    
    // MARK: - Persona List View
    
    private var personaListView: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(personaManager.personas) { persona in
                    PersonaCardView(
                        persona: persona,
                        onTap: {
                            selectedPersona = persona
                            showingChat = true
                        },
                        onInfo: {
                            selectedPersona = persona
                            showingPersonaDetail = true
                        }
                    )
                }
            }
            .padding(.horizontal)
            .padding(.top, 16)
        }
    }
}

// MARK: - Supporting Views

struct PersonaCardView: View {
    let persona: UserPersona
    let onTap: () -> Void
    let onInfo: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // アバター
                ZStack {
                    Circle()
                        .fill(persona.customization.avatarColor)
                        .frame(width: 60, height: 60)
                    
                    if let emoji = persona.customization.avatarEmoji {
                        Text(emoji)
                            .font(.title)
                    } else {
                        Text(String(persona.name.prefix(1)))
                            .font(.title)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                    }
                }
                
                // 情報
                VStack(alignment: .leading, spacing: 4) {
                    Text(persona.name)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text(persona.relationship)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text(persona.personality.prefix(2).joined(separator: " • "))
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                // 詳細ボタン
                Button(action: onInfo) {
                    Image(systemName: "info.circle")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
                .buttonStyle(PlainButtonStyle())
                
                // チャット開始アイコン
                Image(systemName: "chevron.right")
                    .font(.body)
                    .foregroundColor(.gray)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct PersonaDetailView: View {
    let persona: UserPersona
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // アバター
                    HStack {
                        Spacer()
                        
                        ZStack {
                            Circle()
                                .fill(persona.customization.avatarColor)
                                .frame(width: 100, height: 100)
                            
                            if let emoji = persona.customization.avatarEmoji {
                                Text(emoji)
                                    .font(.system(size: 40))
                            } else {
                                Text(String(persona.name.prefix(1)))
                                    .font(.system(size: 40))
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                            }
                        }
                        
                        Spacer()
                    }
                    
                    // 基本情報
                    VStack(alignment: .leading, spacing: 16) {
                        DetailSection(
                            title: "基本情報",
                            items: [
                                ("名前", persona.name),
                                ("関係性", persona.relationship),
                                ("話し方", persona.speechStyle)
                            ]
                        )
                        
                        DetailSection(
                            title: "性格",
                            items: persona.personality.map { ("", $0) }
                        )
                        
                        DetailSection(
                            title: "口癖",
                            items: persona.catchphrases.map { ("", $0) }
                        )
                        
                        DetailSection(
                            title: "好きな話題",
                            items: persona.favoriteTopics.map { ("", $0) }
                        )
                    }
                }
                .padding()
            }
            .navigationTitle("ペルソナ詳細")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                trailing: Button("完了") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
}

struct DetailSection: View {
    let title: String
    let items: [(String, String)]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
            
            ForEach(items.indices, id: \.self) { index in
                let item = items[index]
                HStack {
                    if !item.0.isEmpty {
                        Text(item.0 + ":")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .frame(width: 60, alignment: .leading)
                    }
                    
                    Text(item.1)
                        .font(.subheadline)
                        .foregroundColor(.primary)
                    
                    Spacer()
                }
                .padding(.vertical, 2)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Preview

struct AIView_Previews: PreviewProvider {
    static var previews: some View {
        AIView()
    }
}
