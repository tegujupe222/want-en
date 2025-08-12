import SwiftUI

struct SetupPersonaView: View {
    @StateObject private var personaManager = PersonaManager.shared
    @Environment(\.dismiss) private var dismiss
    
    // Optional callback function
    let onComplete: ((UserPersona) -> Void)?
    let editingPersona: UserPersona?
    
    @State private var setupMode: SetupMode = .selection
    @State private var showingFileImport = false
    
    // Form state variables
    @State private var name: String = ""
    @State private var relationship: String = ""
    @State private var selectedPersonality: Set<String> = []
    @State private var speechStyle: String = ""
    @State private var catchphrases: String = ""
    @State private var favoriteTopics: String = ""
    @State private var selectedMood: PersonaMood = .happy
    @State private var selectedEmoji: String = "😊"
    @State private var selectedAvatarImage: UIImage?  // ✅ Selected image
    @State private var avatarImageFileName: String?   // ✅ Saved image filename
    @State private var selectedColor: Color = .blue
    @State private var currentStep: Int = 0
    @State private var showingRelationshipPicker = false
    
    // ✅ For hiding keyboard
    @FocusState private var isTextFieldFocused: Bool
    
    private let personalityOptions = [
        "Kind", "Caring", "Good listener", "Cheerful", "Humorous",
        "Serious", "Calm", "Passionate", "Creative", "Intelligent", "Friendly"
    ]
    
    private let relationshipOptions = [
        "Family", "Friend", "Lover", "Teacher", "Colleague", "Senior", "Junior", "Important person"
    ]
    
    private let speechStyleOptions = [
        "Polite and warm tone", "Friendly tone", "Casual tone",
        "Calm tone", "Energetic and bright tone", "Gentle and caring tone"
    ]
    
    enum SetupMode {
        case selection
        case manual
        case automatic
    }
    
    // Multiple initializers
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
        
        // Set initial values for edit mode
        self._name = State(initialValue: editingPersona.name)
        self._relationship = State(initialValue: editingPersona.relationship)
        self._selectedPersonality = State(initialValue: Set(editingPersona.personality))
        self._speechStyle = State(initialValue: editingPersona.speechStyle)
        self._catchphrases = State(initialValue: editingPersona.catchphrases.joined(separator: ", "))
        self._favoriteTopics = State(initialValue: editingPersona.favoriteTopics.joined(separator: ", "))
        self._selectedMood = State(initialValue: editingPersona.mood)
        self._selectedEmoji = State(initialValue: editingPersona.customization.avatarEmoji ?? "😊")
        self._avatarImageFileName = State(initialValue: editingPersona.customization.avatarImageFileName)  // ✅ Initialize image filename
        self._selectedColor = State(initialValue: editingPersona.customization.avatarColor)
        self._setupMode = State(initialValue: .manual)
        self._currentStep = State(initialValue: 5)
    }
    
    var body: some View {
        // Avoid NavigationView duplication by using conditionally
        Group {
            if editingPersona != nil {
                // Don't use NavigationView for edit mode
                mainContent
            } else {
                // Use NavigationView only for new creation
                NavigationView {
                    mainContent
                }
            }
        }
        .onAppear {
            // Switch to manual setup mode for edit mode
            if editingPersona != nil {
                setupMode = .manual
            }
        }
    }
    
    private var mainContent: some View {
        VStack(spacing: 0) {
            // Progress bar (manual setup only)
            if setupMode == .manual {
                ProgressView(value: Double(currentStep), total: 5.0)
                    .progressViewStyle(LinearProgressViewStyle())
                    .padding()
            }
            
            // Main content
            Group {
                switch setupMode {
                case .selection:
                    if editingPersona != nil {
                        // Go directly to manual setup for edit mode
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
            
            // Navigation buttons (manual setup only)
            if setupMode == .manual {
                navigationButtons
            }
        }
        .navigationTitle(editingPersona != nil ? "Edit Profile" :
                       setupMode == .selection ? "Choose Setup Method" : "Set Up Person to Chat With")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") {
                    dismiss()
                }
            }
        }
        // ✅ Improved keyboard hiding
        .simultaneousGesture(
            TapGesture()
                .onEnded { _ in
                    hideKeyboard()
                }
        )
    }
    
    // ✅ Method for hiding keyboard
    private func hideKeyboard() {
        isTextFieldFocused = false
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    private var setupModeSelectionView: some View {
        VStack(spacing: 32) {
            // Header
            VStack(spacing: 16) {
                Image(systemName: "person.badge.plus")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                
                Text("Choose Setup Method")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("You can set up manually or\nstart with quick setup")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            // Setup method options
            VStack(spacing: 16) {
                // ✅ Quick setup button - improved responsiveness
                Button(action: {
                    setupMode = .automatic
                }) {
                    SetupOptionCard(
                        icon: "magic.wand",
                        title: "Quick Setup (Recommended)",
                        description: "Start immediately with\nbasic information only",
                        badge: "Quick",
                        isRecommended: true
                    )
                }
                
                // ✅ Manual setup button - improved responsiveness
                Button(action: {
                    setupMode = .manual
                }) {
                    SetupOptionCard(
                        icon: "hand.raised",
                        title: "Detailed Setup",
                        description: "Set up personality and\nspeech style in detail",
                        badge: "Detailed",
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
                // Header
                VStack(spacing: 16) {
                    Image(systemName: "magic.wand")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                    
                    Text("Quick Setup")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Enter basic information to\nstart chatting immediately")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                // Simple form
                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Person's Name")
                            .font(.headline)
                        TextField("e.g., Mom, Mr. Tanaka, Friend", text: $name)
                            .textFieldStyle(.roundedBorder)
                            .focused($isTextFieldFocused)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Relationship")
                            .font(.headline)
                        
                        // ✅ Improved picker
                        Button(action: {
                            showingRelationshipPicker = true
                        }) {
                            HStack {
                                Text(relationship.isEmpty ? "Please select" : relationship)
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
                        .confirmationDialog("Select Relationship", isPresented: $showingRelationshipPicker) {
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
                
                // Create button
                Button(action: {
                    savePersona()
                }) {
                    Text("Create Persona")
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
            // Step 1: Basic info
            stepOneView.tag(0)
            
            // Step 2: Relationship and personality
            stepTwoView.tag(1)
            
            // Step 3: Speech style
            stepThreeView.tag(2)
            
            // Step 4: Topics and catchphrases
            stepFourView.tag(3)
            
            // Step 5: Appearance settings
            stepFiveView.tag(4)
            
            // Step 6: Confirmation
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
                    Text("Back")
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
                Text(currentStep == 5 ? "Complete" : "Next")
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
                    Text("What's the name of the person you want to chat with?")
                        .font(.headline)
                    
                    TextField("e.g., Dad, Mr. Tanaka, Important person", text: $name)
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
                    Text("What's your relationship with this person?")
                        .font(.headline)
                    
                    // ✅ Improved grid layout
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
                                
                                // Adjustment for odd number
                                if row.count == 1 {
                                    Spacer()
                                        .frame(maxWidth: .infinity)
                                }
                            }
                        }
                    }
                }
                
                VStack(alignment: .leading, spacing: 16) {
                    Text("What's their personality like? (Multiple selection)")
                        .font(.headline)
                    
                    // ✅ Improved grid layout
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
                                
                                // Adjustment for odd number
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
                    Text("How does this person speak?")
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
                    Text("What catchphrases did they often use?")
                        .font(.headline)
                    
                    TextField("e.g., I see, That's right, It's okay (comma separated)", text: $catchphrases)
                        .textFieldStyle(.roundedBorder)
                        .focused($isTextFieldFocused)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("What topics did they often talk about?")
                        .font(.headline)
                    
                    TextField("e.g., Work, Hobbies, Family, Memories (comma separated)", text: $favoriteTopics)
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
                Text("Set up appearance")
                    .font(.headline)
                
                // ✅ Image selection section
                ImageOptionsView(
                    selectedImage: $selectedAvatarImage,
                    avatarEmoji: $selectedEmoji,
                    showingImagePicker: .constant(false),
                    onImageSelected: { image in
                        selectedAvatarImage = image
                        selectedEmoji = "" // Clear emoji when image is selected
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
                    // Avatar emoji (only show when no image is selected)
                    if selectedAvatarImage == nil {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Avatar Emoji")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            
                            TextField("😊", text: $selectedEmoji)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 100)
                                .focused($isTextFieldFocused)
                        }
                    }
                    
                    // Color selection
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Color Theme")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        
                        ColorPicker("Select Color", selection: $selectedColor)
                            .labelsHidden()
                    }
                    
                    // Mood setting
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Basic Mood")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        
                        Picker("Mood", selection: $selectedMood) {
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
                    
                    // Preview
                    VStack(spacing: 8) {
                        Text("Preview")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        
                        // ✅ Image-supported preview
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
                                name: name.isEmpty ? "Name" : name,
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
                Text("Please confirm your settings")
                    .font(.headline)
                
                VStack(alignment: .leading, spacing: 12) {
                    InfoRow(label: "Name", value: name)
                    InfoRow(label: "Relationship", value: relationship)
                    InfoRow(label: "Personality", value: Array(selectedPersonality).joined(separator: ", "))
                    InfoRow(label: "Speech Style", value: speechStyle)
                    InfoRow(label: "Mood", value: selectedMood.displayName)
                    
                    if !catchphrases.isEmpty {
                        InfoRow(label: "Catchphrases", value: catchphrases)
                    }
                    
                    if !favoriteTopics.isEmpty {
                        InfoRow(label: "Topics", value: favoriteTopics)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                Text("Start chatting with \"\(name)\" with these settings. You can change settings anytime.")
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
        // Apply default settings based on relationship
        switch relationship {
        case "Family":
            selectedPersonality = Set(["Kind", "Caring"])
            speechStyle = "Polite and warm tone"
            catchphrases = "It's okay, Good job"
            favoriteTopics = "Daily events, Health, Family matters"
            selectedEmoji = "👨‍👩‍👧‍👦"
            selectedColor = Color.personaPink  // Use safe color
            
        case "Friend":
            selectedPersonality = Set(["Cheerful", "Friendly"])
            speechStyle = "Friendly tone"
            catchphrases = "I see, That's amazing"
            favoriteTopics = "Hobbies, Entertainment, Daily conversation"
            selectedEmoji = "😊"
            selectedColor = Color.personaLightBlue  // Use safe color
            
        case "Lover":
            selectedPersonality = Set(["Kind", "Loving"])
            speechStyle = "Gentle and caring tone"
            catchphrases = "I love you, It's okay"
            favoriteTopics = "Memories, Future plans, Love expressions"
            selectedEmoji = "💕"
            selectedColor = Color.personaPink  // Use safe color
            
        default:
            selectedPersonality = Set(["Friendly"])
            speechStyle = "Friendly tone"
            catchphrases = "Nice to meet you"
            favoriteTopics = "Daily conversation"
            selectedEmoji = "😊"
            selectedColor = .blue  // Standard blue is safe
        }
    }
    
    private func savePersona() {
        let personality = selectedPersonality.isEmpty ? ["Friendly"] : Array(selectedPersonality)
        let catchphrasesArray = catchphrases.isEmpty ? ["Nice to meet you"] :
            catchphrases.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        let topicsArray = favoriteTopics.isEmpty ? ["Daily conversation"] :
            favoriteTopics.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        
        let persona: UserPersona
        
        // Update existing persona for edit mode
        if let editing = editingPersona {
            // ✅ Image save process
            var finalImageFileName = avatarImageFileName
            if let selectedImage = selectedAvatarImage {
                finalImageFileName = ImageManager.shared.saveAvatarImage(selectedImage, for: editing.id)
                
                // Delete old image file if exists
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
            
            // Safety check
            customization.makeSafe()
            
            persona = UserPersona(
                id: editing.id,
                name: name,
                relationship: relationship,
                personality: personality,
                speechStyle: speechStyle.isEmpty ? "Friendly tone" : speechStyle,
                catchphrases: catchphrasesArray,
                favoriteTopics: topicsArray,
                mood: selectedMood,
                customization: customization
            )
            personaManager.updatePersona(persona)
        } else {
            // New creation
            let newPersonaId = UUID().uuidString
            
            // ✅ Image save process
            var finalImageFileName: String?
            var finalEmoji = selectedEmoji.isEmpty ? nil : selectedEmoji
            
            if let selectedImage = selectedAvatarImage {
                finalImageFileName = ImageManager.shared.saveAvatarImage(selectedImage, for: newPersonaId)
                finalEmoji = nil // Clear emoji when image exists
            }
            
            var customization = PersonaCustomization(
                avatarEmoji: finalEmoji,
                avatarImageFileName: finalImageFileName,
                avatarColor: selectedColor
            )
            
            // Safety check
            customization.makeSafe()
            
            persona = UserPersona(
                id: newPersonaId,
                name: name,
                relationship: relationship,
                personality: personality,
                speechStyle: speechStyle.isEmpty ? "Friendly tone" : speechStyle,
                catchphrases: catchphrasesArray,
                favoriteTopics: topicsArray,
                mood: selectedMood,
                customization: customization
            )
            
            personaManager.addPersona(persona)
        }
        
        // Call callback
        onComplete?(persona)
        
        dismiss()
    }
}

// ✅ Improved SetupOptionCard
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
            Text(value.isEmpty ? "Not set" : value)
                .font(.body)
        }
    }
}

// ✅ Array chunking extension
extension Array {
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}

// AvatarView is defined in separate file

#Preview {
    SetupPersonaView()
}
