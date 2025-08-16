import SwiftUI

struct AIView: View {
    @StateObject private var personaManager = PersonaManager.shared
    @State private var selectedPersona: UserPersona? {
        didSet {
            print("📱 selectedPersona didSet triggered")
            if let persona = selectedPersona {
                print("📱 selectedPersona changed to: \(persona.name) (ID: \(persona.id))")
            } else {
                print("📱 selectedPersona cleared")
            }
            print("📱 selectedPersona didSet completed")
        }
    }
    
    // Initialize with first persona if available
    private var initialPersona: UserPersona? {
        personaManager.personas.first
    }
    @State private var showingChat = false
    @State private var showingPersonaDetail = false
    
    init() {
        print("🎯 AIView init called")
        print("🎯 AIView init - personas count: \(PersonaManager.shared.personas.count)")
    }
    
    var body: some View {
        let isIPad = UIDevice.current.userInterfaceIdiom == .pad
        
        Group {
            if isIPad {
                // iPad layout - use simpler navigation
                NavigationStack {
                HStack(spacing: 0) {
                    // Sidebar
                    VStack(spacing: 0) {
                        headerView
                        
                        if personaManager.personas.isEmpty {
                            emptyStateView
                        } else {
                            personaListSidebar
                        }
                        
                        Spacer()
                    }
                    .frame(width: 300)
                    .background(Color(.systemGroupedBackground))
                    
                    // Detail view
                    if let selected = selectedPersona {
                        ChatView(isAIMode: true, persona: selected)
                            .navigationTitle(selected.name)
                            .navigationBarTitleDisplayMode(.inline)
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
                .navigationTitle("AI Chat")
                .onAppear {
                    print("🎯 AIView appeared (iPad), personas count: \(personaManager.personas.count)")
                    if selectedPersona == nil && !personaManager.personas.isEmpty {
                        selectedPersona = personaManager.personas.first
                        print("🎯 Auto-selecting first persona (iPad): \(personaManager.personas.first?.name ?? "unknown")")
                    }
                }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                    print("🎯 AIView app became active (iPad)")
                }
                .task {
                    print("🎯 AIView task started (iPad)")
                }
                .onChange(of: personaManager.personas) { oldValue, newValue in
                    print("🎯 Personas changed (iPad), count: \(newValue.count)")
                    if selectedPersona == nil && !newValue.isEmpty {
                        selectedPersona = newValue.first
                        print("🎯 Auto-selecting first persona after change (iPad): \(newValue.first?.name ?? "unknown")")
                    }
                }
                .sheet(isPresented: $showingPersonaDetail) {
                    if let persona = selectedPersona {
                        PersonaDetailView(persona: persona)
                    }
                }
            }
            } else {
                // iPhone layout - use NavigationSplitView
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
                    NavigationStack {
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
            .onAppear {
                print("🎯 AIView appeared, personas count: \(personaManager.personas.count)")
                if selectedPersona == nil && !personaManager.personas.isEmpty {
                    selectedPersona = personaManager.personas.first
                    print("🎯 Auto-selecting first persona: \(personaManager.personas.first?.name ?? "unknown")")
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                print("🎯 AIView app became active")
            }
            .task {
                print("🎯 AIView task started")
            }
            .onChange(of: personaManager.personas) { oldValue, newValue in
                print("🎯 Personas changed, count: \(newValue.count)")
                if selectedPersona == nil && !newValue.isEmpty {
                    selectedPersona = newValue.first
                    print("🎯 Auto-selecting first persona after change: \(newValue.first?.name ?? "unknown")")
                }
            }
            .sheet(isPresented: $showingPersonaDetail) {
                if let persona = selectedPersona {
                    PersonaDetailView(persona: persona)
                }
            }
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
        List(personaManager.personas, id: \.id) { persona in
            PersonaSidebarCardView(
                persona: persona,
                selectedPersona: selectedPersona,
                onTap: {
                    print("🎯 Setting selectedPersona to: \(persona.name)")
                    print("🎯 Previous selectedPersona: \(selectedPersona?.name ?? "nil")")
                    print("🎯 New persona ID: \(persona.id)")
                    print("🎯 Previous persona ID: \(selectedPersona?.id ?? "nil")")
                    selectedPersona = persona
                    print("🎯 selectedPersona updated to: \(selectedPersona?.name ?? "nil")")
                },
                onInfo: {
                    selectedPersona = persona
                    showingPersonaDetail = true
                }
            )
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)
        }
        .listStyle(SidebarListStyle())
        .onAppear {
            print("🎯 personaListSidebar appeared, personas count: \(personaManager.personas.count)")
        }
    }
}

// MARK: - Supporting Views

struct PersonaSidebarCardView: View {
    let persona: UserPersona
    let selectedPersona: UserPersona?
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
            Button(action: {
                print("ℹ️ Info button tapped for: \(persona.name)")
                onInfo()
            }) {
                Image(systemName: "info.circle")
                    .font(.caption)
                    .foregroundColor(.blue)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(selectedPersona?.id == persona.id ? Color.blue.opacity(0.1) : Color.clear)
        .cornerRadius(8)
        .contentShape(Rectangle())
        .onTapGesture {
            print("🔘 Persona tapped: \(persona.name)")
            print("🔘 Current selectedPersona: \(selectedPersona?.name ?? "nil")")
            print("🔘 Tapped persona ID: \(persona.id)")
            print("🔘 Selected persona ID: \(selectedPersona?.id ?? "nil")")
            onTap()
        }
    }
}

struct PersonaDetailView: View {
    let persona: UserPersona
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
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
                    dismiss()
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
