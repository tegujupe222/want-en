import SwiftUI

struct AIView: View {
    @StateObject private var personaManager = PersonaManager.shared
    @State private var selectedPersona: UserPersona?
    @State private var showingChat = false
    @State private var showingPersonaDetail = false
    
    var body: some View {
        NavigationSplitView {
            // Sidebar
            VStack(spacing: 0) {
                // Header
                headerView
                
                if personaManager.personas.isEmpty {
                    // Empty state
                    emptyStateView
                } else {
                    // Persona selection list
                    personaListSidebar
                }
                
                Spacer()
            }
            .navigationTitle("AI Chat")
        } detail: {
            // Detail view
            if let selected = selectedPersona {
                NavigationView {
                    ChatView(isAIMode: true, persona: selected)
                        .navigationTitle(selected.name)
                        .navigationBarTitleDisplayMode(.inline)
                }
            } else {
                VStack(spacing: 20) {
                    Image(systemName: "person.crop.circle.badge.questionmark")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                    
                    Text("Select a persona from the sidebar")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text("Choose someone to start an AI chat with")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .navigationSplitViewStyle(.balanced)
        .sheet(isPresented: $showingPersonaDetail) {
            if let persona = selectedPersona {
                PersonaDetailView(persona: persona)
            }
        }
    }
    
    // MARK: - Header View
    
    private var headerView: some View {
        VStack(spacing: 16) {
            // Subtitle
            Text("Select a persona to chat with")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.horizontal)
                .padding(.top, 16)
        }
        .padding(.bottom, 8)
    }
    
    // MARK: - Empty State View
    
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "person.crop.circle.badge.plus")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            VStack(spacing: 8) {
                Text("No personas yet")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text("Create a persona in the \"People\" tab\nto enjoy AI chat")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
        }
        .padding(.horizontal)
    }
    
    // MARK: - Persona List Sidebar
    
    private var personaListSidebar: some View {
        List(personaManager.personas, id: \.id, selection: $selectedPersona) { persona in
            PersonaSidebarCardView(
                persona: persona,
                onTap: {
                    selectedPersona = persona
                },
                onInfo: {
                    selectedPersona = persona
                    showingPersonaDetail = true
                }
            )
        }
        .listStyle(SidebarListStyle())
        .navigationBarHidden(true)
    }
}

// MARK: - Supporting Views

struct PersonaSidebarCardView: View {
    let persona: UserPersona
    let onTap: () -> Void
    let onInfo: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Avatar
            ZStack {
                Circle()
                    .fill(persona.customization.avatarColor)
                    .frame(width: 40, height: 40)
                
                if let emoji = persona.customization.avatarEmoji {
                    Text(emoji)
                        .font(.title3)
                } else {
                    Text(String(persona.name.prefix(1)))
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                }
            }
            
            // Information
            VStack(alignment: .leading, spacing: 2) {
                Text(persona.name)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text(persona.relationship)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(persona.personality.prefix(2).joined(separator: " • "))
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            // Info button
            Button(action: onInfo) {
                Image(systemName: "info.circle")
                    .font(.caption)
                    .foregroundColor(.blue)
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

struct PersonaDetailView: View {
    let persona: UserPersona
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Avatar
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
                    
                    // Basic information
                    VStack(alignment: .leading, spacing: 16) {
                        DetailSection(
                            title: "Basic Info",
                            items: [
                                ("Name", persona.name),
                                ("Relationship", persona.relationship),
                                ("Speech Style", persona.speechStyle)
                            ]
                        )
                        
                        DetailSection(
                            title: "Personality",
                            items: persona.personality.map { ("", $0) }
                        )
                        
                        DetailSection(
                            title: "Catchphrases",
                            items: persona.catchphrases.map { ("", $0) }
                        )
                        
                        DetailSection(
                            title: "Favorite Topics",
                            items: persona.favoriteTopics.map { ("", $0) }
                        )
                    }
                }
                .padding()
            }
            .navigationTitle("Persona Details")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                trailing: Button("Done") {
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
