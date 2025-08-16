import SwiftUI

struct PersonaListView: View {
    @StateObject private var personaManager = PersonaManager.shared
    @StateObject private var personaLoader = PersonaLoader.shared
    @State private var showingCreatePersona = false
    @State private var selectedPersona: UserPersona?
    @State private var showingPersonaDetail = false
    @State private var editingPersona: UserPersona?
    @State private var showingEditPersona = false
    
    var body: some View {
        NavigationSplitView {
            // Sidebar
            VStack {
                if personaManager.personas.isEmpty {
                    emptyStateView
                } else {
                    personaListSidebar
                }
            }
            .navigationTitle("People")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingCreatePersona = true
                    }) {
                        Image(systemName: "plus")
                            .font(.title2)
                    }
                }
            }
        } detail: {
            // Detail view
            if let selected = selectedPersona {
                personaDetailView(persona: selected)
            } else {
                Text("Select a persona from the sidebar")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .navigationSplitViewStyle(.balanced)
        .sheet(isPresented: $showingCreatePersona) {
            SetupPersonaView { newPersona in
                // Select the newly created persona
                personaLoader.setCurrentPersona(newPersona)
            }
        }
        .sheet(isPresented: $showingEditPersona) {
            if let persona = editingPersona {
                SetupPersonaView(editingPersona: persona)
            }
        }
        .ignoresSafeArea(.all, edges: .all)
    }
    
    // MARK: - Sidebar Content
    
    private var personaListSidebar: some View {
        List(personaManager.personas, id: \.id, selection: $selectedPersona) { persona in
            PersonaSidebarRowView(
                persona: persona,
                isSelected: personaLoader.currentPersona?.id == persona.id,
                onTap: {
                    selectedPersona = persona
                },
                onEdit: {
                    editingPersona = persona
                    showingEditPersona = true
                },
                onDelete: {
                    personaManager.deletePersona(persona)
                    if selectedPersona?.id == persona.id {
                        selectedPersona = nil
                    }
                },
                onSelect: {
                    personaLoader.setCurrentPersona(persona)
                }
            )
        }
        .listStyle(SidebarListStyle())
    }
    
    // MARK: - Detail View
    
    private func personaDetailView(persona: UserPersona) -> some View {
        ScrollView {
            VStack(spacing: 24) {
                // Avatar and basic info
                VStack(spacing: 16) {
                    AvatarView(persona: persona, size: 120)
                    
                    VStack(spacing: 8) {
                        Text(persona.name)
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text(persona.relationship)
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        if personaLoader.currentPersona?.id == persona.id {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.accentColor)
                                Text("Currently Selected")
                                    .font(.subheadline)
                                    .foregroundColor(.accentColor)
                            }
                        }
                    }
                }
                
                // Action buttons
                HStack(spacing: 16) {
                    Button(action: {
                        personaLoader.setCurrentPersona(persona)
                    }) {
                        HStack {
                            Image(systemName: "checkmark.circle")
                            Text("Select")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color.accentColor)
                        .cornerRadius(25)
                    }
                    
                    Button(action: {
                        editingPersona = persona
                        showingEditPersona = true
                    }) {
                        HStack {
                            Image(systemName: "pencil")
                            Text("Edit")
                        }
                        .font(.headline)
                        .foregroundColor(.accentColor)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color.accentColor.opacity(0.1))
                        .cornerRadius(25)
                    }
                }
                
                // Details sections
                VStack(spacing: 20) {
                    detailSection(title: "Personality", items: persona.personality)
                    detailSection(title: "Speech Style", items: [persona.speechStyle])
                    detailSection(title: "Catchphrases", items: persona.catchphrases)
                    detailSection(title: "Favorite Topics", items: persona.favoriteTopics)
                }
            }
            .padding()
        }
        .navigationTitle(persona.name)
        .navigationBarTitleDisplayMode(.large)
    }
    
    private func detailSection(title: String, items: [String]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(alignment: .leading, spacing: 8) {
                ForEach(items, id: \.self) { item in
                    HStack {
                        Image(systemName: "circle.fill")
                            .font(.system(size: 6))
                            .foregroundColor(.secondary)
                        
                        Text(item)
                            .font(.body)
                        
                        Spacer()
                    }
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }
    
    // MARK: - Empty State View
    
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "person.crop.circle.badge.plus")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            VStack(spacing: 8) {
                Text("Create a persona")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text("Create your own special person and\nstart enjoyable conversations")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Button(action: {
                showingCreatePersona = true
            }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Create Persona")
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(Color.accentColor)
                .cornerRadius(25)
            }
            
            Spacer()
        }
        .padding(.horizontal)
    }
}

// MARK: - Supporting Views

struct PersonaSidebarRowView: View {
    let persona: UserPersona
    let isSelected: Bool
    let onTap: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    let onSelect: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            AvatarView(persona: persona, size: 40)
            
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(persona.name)
                        .font(.body)
                        .fontWeight(.medium)
                        .lineLimit(1)
                    
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.accentColor)
                            .font(.caption)
                    }
                }
                
                Text(persona.relationship)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            Menu {
                Button("Select") {
                    onSelect()
                }
                
                Button("Edit") {
                    onEdit()
                }
                
                Button("Delete", role: .destructive) {
                    onDelete()
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
    }
}

// MARK: - Create Persona View (Simple Version)

struct CreatePersonaView: View {
    @StateObject private var personaManager = PersonaManager.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var name = ""
    @State private var relationship = ""
    @State private var personality: [String] = []
    @State private var speechStyle = ""
    @State private var catchphrases: [String] = []
    @State private var favoriteTopics: [String] = []
    @State private var mood: PersonaMood = .happy
    @State private var selectedEmoji = "😊"
    @State private var selectedColor = Color.blue
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Basic Information")) {
                    TextField("Name", text: $name)
                    TextField("Relationship", text: $relationship)
                    TextField("Speech Style", text: $speechStyle)
                }
                
                Section(header: Text("Appearance")) {
                    HStack {
                        Text("Emoji")
                        Spacer()
                        TextField("😊", text: $selectedEmoji)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 50)
                    }
                    
                    ColorPicker("Color", selection: $selectedColor)
                }
                
                Section(header: Text("Personality")) {
                    Picker("Mood", selection: $mood) {
                        ForEach(PersonaMood.allCases, id: \.self) { mood in
                            HStack {
                                Text(mood.emoji)
                                Text(mood.displayName)
                            }
                            .tag(mood)
                        }
                    }
                }
            }
            .navigationTitle("Create Persona")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") {
                        createPersona()
                    }
                    .disabled(name.isEmpty || relationship.isEmpty)
                }
            }
        }
    }
    
    private func createPersona() {
        let newPersona = UserPersona(
            name: name,
            relationship: relationship,
            personality: personality.isEmpty ? ["Friendly"] : personality,
            speechStyle: speechStyle.isEmpty ? "Friendly tone" : speechStyle,
            catchphrases: catchphrases.isEmpty ? ["Nice to meet you!"] : catchphrases,
            favoriteTopics: favoriteTopics.isEmpty ? ["Daily conversation"] : favoriteTopics,
            mood: mood,
            customization: PersonaCustomization(
                avatarEmoji: selectedEmoji.isEmpty ? nil : selectedEmoji,
                avatarColor: selectedColor
            )
        )
        
        personaManager.addPersona(newPersona)
        dismiss()
    }
}

// MARK: - Preview

struct PersonaListView_Previews: PreviewProvider {
    static var previews: some View {
        PersonaListView()
    }
}
