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
        NavigationView {
            VStack {
                if personaManager.personas.isEmpty {
                    emptyStateView
                } else {
                    personaListContent
                }
            }
            .navigationTitle("People")
            .navigationBarTitleDisplayMode(.inline)
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
        }
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
        .alert("Persona Details", isPresented: $showingPersonaDetail) {
            Button("Edit") {
                editingPersona = selectedPersona
                showingEditPersona = true
            }
            Button("Select") {
                if let persona = selectedPersona {
                    personaLoader.setCurrentPersona(persona)
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            if let persona = selectedPersona {
                Text("\(persona.name)\n\(persona.relationship)\n\(persona.personalityText)")
            }
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
    
    // MARK: - Persona List Content
    
    private var personaListContent: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(personaManager.personas) { persona in
                    PersonaRowView(
                        persona: persona,
                        isSelected: personaLoader.currentPersona?.id == persona.id,
                        onTap: {
                            selectedPersona = persona
                            showingPersonaDetail = true
                        },
                        onEdit: {
                            editingPersona = persona
                            showingEditPersona = true
                        },
                        onDelete: {
                            personaManager.deletePersona(persona)
                        },
                        onSelect: {
                            personaLoader.setCurrentPersona(persona)
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

struct PersonaRowView: View {
    let persona: UserPersona
    let isSelected: Bool
    let onTap: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Avatar
                AvatarView(
                    persona: persona,  // ✅ Create AvatarView directly from Persona
                    size: 60
                )
                
                // Information
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(persona.name)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        if isSelected {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.accentColor)
                                .font(.title3)
                        }
                    }
                    
                    Text(persona.relationship)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text(persona.personality.prefix(2).joined(separator: " • "))
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                    
                    HStack {
                        Text(persona.mood.emoji)
                        Text(persona.mood.displayName)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Menu button
                Menu {
                    Button("Select") {
                        onSelect()
                    }
                    
                    Button("View Details") {
                        onTap()
                    }
                    
                    Button("Edit") {
                        onEdit()
                    }
                    
                    Button("Delete", role: .destructive) {
                        onDelete()
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.title3)
                        .foregroundColor(.gray)
                        .padding(.trailing, 8)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding()
            .background(isSelected ? Color.accentColor.opacity(0.1) : Color(.systemGray6))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Create Persona View (Simple Version)

struct CreatePersonaView: View {
    @StateObject private var personaManager = PersonaManager.shared
    @Environment(\.presentationMode) var presentationMode
    
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
        NavigationView {
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
                        presentationMode.wrappedValue.dismiss()
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
        presentationMode.wrappedValue.dismiss()
    }
}

// MARK: - Preview

struct PersonaListView_Previews: PreviewProvider {
    static var previews: some View {
        PersonaListView()
    }
}
