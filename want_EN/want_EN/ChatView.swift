import SwiftUI

struct ChatView: View {
    @StateObject private var viewModel: ChatViewModel
    @Environment(\.dismiss) private var dismiss
    
    let isAIMode: Bool
    let selectedPersona: UserPersona?
    
    @State private var showingPersonaSelection = false
    @State private var isInitialized = false
    @State private var initializationAttempts = 0  // ✅ Track initialization attempts
    @State private var showError = false  // ✅ Error display flag
    
    init(isAIMode: Bool = false, persona: UserPersona? = nil, chatViewModel: ChatViewModel? = nil) {
        self.isAIMode = isAIMode
        self.selectedPersona = persona
        self._viewModel = StateObject(wrappedValue: chatViewModel ?? ChatViewModel())
        print("🔧 ChatView init - persona: \(persona?.name ?? "nil"), isAIMode: \(isAIMode)")
    }
    
    var body: some View {
        ZStack {
            if isInitialized && viewModel.selectedPersona != nil {
                // ✅ Display main content after complete initialization
                mainContent
            } else if showError {
                // ✅ Error screen
                errorView
            } else {
                // ✅ Loading screen during initialization
                loadingView
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            setupChatWithRetry()
        }
        .background(Color(.systemBackground))
        .ignoresSafeArea(.all, edges: .all)
        .alert("Subscription Required", isPresented: $viewModel.showSubscriptionAlert) {
            Button("Open Settings") {
                // Open settings screen
                // Simplified here - just close alert
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text(viewModel.subscriptionAlertMessage)
        }
    }
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .stroke(Color(.systemGray).opacity(0.3), lineWidth: 4)
                    .frame(width: 50, height: 50)
                
                Circle()
                    .trim(from: 0, to: 0.7)
                    .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .frame(width: 50, height: 50)
                    .rotationEffect(.degrees(-90))
                    .animation(Animation.linear(duration: 1).repeatForever(autoreverses: false), value: isInitialized)
            }
            
            VStack(spacing: 8) {
                Text("Preparing chat...")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                if initializationAttempts > 0 {
                    Text("Attempt: \(initializationAttempts + 1)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if let persona = selectedPersona {
                    Text(persona.name)
                        .font(.subheadline)
                        .foregroundColor(.blue)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
    
    // MARK: - Error View
    
    private var errorView: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 50))
                .foregroundColor(.orange)
            
            Text("Failed to load chat")
                .font(.headline)
                .foregroundColor(.primary)
            
            Text("Please try again")
                .font(.body)
                .foregroundColor(.secondary)
            
            Button("Retry") {
                retryInitialization()
            }
            .buttonStyle(.borderedProminent)
            
            Button("Back") {
                dismiss()
            }
            .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
    
    // MARK: - Main Content
    
    private var mainContent: some View {
        GeometryReader { geometry in
        VStack(spacing: 0) {
            // Header
            headerView
            
            // Message list
            messagesScrollView
                    .frame(maxWidth: geometry.size.width > 768 ? 600 : nil) // Limit max width on iPad
                    .frame(maxWidth: .infinity)
            
            // Input area
            messageInputView
                    .frame(maxWidth: geometry.size.width > 768 ? 600 : nil) // Limit max width on iPad
                    .frame(maxWidth: .infinity)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
    
    // MARK: - Header View
    
    private var headerView: some View {
        HStack {
            // Back button
            Button(action: {
                print("🔙 Back from chat screen")
                dismiss()
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                        .font(.title2)
                        .fontWeight(.medium)
                    Text("Back")
                        .font(.body)
                }
                .foregroundColor(.blue)
            }
            
            Spacer()
            
            // Title
            VStack(spacing: 2) {
                if let persona = viewModel.selectedPersona {
                    Text(persona.name)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text(persona.relationship)
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    Text("Chat")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
            }
            
            Spacer()
            
            // Menu button
            Menu {
                if isAIMode {
                    Button("Change Persona") {
                        showingPersonaSelection = true
                    }
                }
                
                Button("Clear Conversation") {
                    Task {
                        await viewModel.clearConversation()
                    }
                }
                
                Button("Debug Info") {
                    viewModel.printDebugInfo()
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .font(.title2)
                    .foregroundColor(.blue)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
        .overlay(
            Rectangle()
                .frame(height: 0.5)
                .foregroundColor(Color(.separator)),
            alignment: .bottom
        )
    }
    
    // MARK: - Messages Scroll View
    
    private var messagesScrollView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 12) {
                    if viewModel.messages.isEmpty {
                        // Empty state display
                        VStack(spacing: 16) {
                            Image(systemName: "bubble.left.and.bubble.right")
                                .font(.system(size: 50))
                                .foregroundColor(.gray.opacity(0.5))
                            
                            Text("Start a conversation")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            
                            Text("Try sending a message\nfrom the input field below")
                                .font(.body)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 50)
                    } else {
                        ForEach(viewModel.messages) { message in
                            MessageBubbleView(
                                message: message,
                                persona: viewModel.selectedPersona ?? UserPersona.defaultPersona
                            )
                            .id(message.id)
                        }
                    }
                    
                    // Typing indicator
                    if viewModel.isTyping {
                        TypingIndicatorView(persona: viewModel.selectedPersona)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
            }
            .onChange(of: viewModel.messages.count) { oldValue, newValue in
                // Auto-scroll when new message is added
                if let lastMessage = viewModel.messages.last {
                    withAnimation(.easeOut(duration: 0.3)) {
                        proxy.scrollTo(lastMessage.id, anchor: .bottom)
                    }
                }
            }
        }
    }
    
    // MARK: - Message Input View
    
    private var messageInputView: some View {
        VStack(spacing: 12) {
            // Text input area
            HStack(spacing: 12) {
                TextField("Type a message...", text: $viewModel.currentMessage, axis: .vertical)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .lineLimit(1...4)
                    .submitLabel(.send)
                    .onSubmit {
                        if canSendMessage {
                            sendMessage()
                        }
                    }
                    .onChange(of: viewModel.currentMessage) { _, newValue in
                        // Character limit
                        if newValue.count > 500 {
                            viewModel.currentMessage = String(newValue.prefix(500))
                        }
                    }
                
                // Send button
                Button(action: sendMessage) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title2)
                        .foregroundColor(canSendMessage ? .blue : .gray)
                }
                .disabled(!canSendMessage)
            }
        }
        .padding(.horizontal)
        .padding(.bottom, 8)
        .background(Color(.systemBackground))
        .overlay(
            Rectangle()
                .frame(height: 0.5)
                .foregroundColor(Color(.separator)),
            alignment: .top
        )
    }
    
    // MARK: - Computed Properties
    
    private var canSendMessage: Bool {
        return !viewModel.currentMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
               !viewModel.isLoading && isInitialized
    }
    
    // MARK: - Methods
    
    // ✅ Initialization with retry functionality
    private func setupChatWithRetry() {
        initializationAttempts += 1
        print("🔄 ChatView initialization started (attempt: \(initializationAttempts))")
        
        Task { @MainActor in
            do {
                // ✅ Ensure sufficient wait time
                try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                
                let personaToUse: UserPersona
                
                if let persona = selectedPersona {
                    print("📋 Using specified persona: \(persona.name)")
                    personaToUse = persona
                } else if isAIMode {
                    print("🤖 AI mode - using default persona")
                    personaToUse = PersonaLoader.shared.safeCurrentPersona
                } else {
                    print("🔧 Using default persona")
                    personaToUse = PersonaLoader.shared.safeCurrentPersona
                }
                
                // ✅ Validate persona
                guard !personaToUse.name.isEmpty else {
                    throw ChatInitializationError.invalidPersona
                }
                
                print("✅ Using persona: \(personaToUse.name)")
                
                // ✅ Load ChatViewModel
                viewModel.loadConversation(for: personaToUse)
                
                // ✅ Confirm initialization completion
                try await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds
                
                guard viewModel.selectedPersona != nil else {
                    throw ChatInitializationError.viewModelNotReady
                }
                
                // ✅ Initialization complete
                withAnimation(.easeInOut(duration: 0.3)) {
                    isInitialized = true
                }
                
                print("✅ ChatView initialization completed - persona: \(viewModel.selectedPersona?.name ?? "nil")")
                
            } catch {
                print("❌ Initialization error (attempt \(initializationAttempts)): \(error)")
                
                if initializationAttempts < 3 {
                    // ✅ Retry up to 3 times
                    try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second wait
                    setupChatWithRetry()
                } else {
                    // ✅ Show error screen after 3 failures
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showError = true
                    }
                }
            }
        }
    }
    
    private func retryInitialization() {
        showError = false
        isInitialized = false
        initializationAttempts = 0
        setupChatWithRetry()
    }
    
    private func sendMessage() {
        guard canSendMessage else { return }
        
        print("📤 Sending message: \(viewModel.currentMessage)")
        
        // Hide keyboard
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        
        // Send message
        Task {
            await viewModel.sendMessage(viewModel.currentMessage)
        }
    }
}

// MARK: - Supporting Views

struct TypingIndicatorView: View {
    let persona: UserPersona?
    
    var body: some View {
        HStack {
            if let persona = persona {
                AvatarView(persona: persona, size: 32)
            }
            
            VStack(alignment: .leading) {
                HStack(spacing: 4) {
                    ForEach(0..<3) { index in
                        Circle()
                            .fill(Color.secondary)
                            .frame(width: 8, height: 8)
                            .scaleEffect(1.0)
                            .animation(
                                Animation.easeInOut(duration: 0.6)
                                    .repeatForever()
                                    .delay(Double(index) * 0.2),
                                value: UUID()
                            )
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color(.systemGray6))
                .cornerRadius(18)
                
                Text("Typing...")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 4)
            }
            
            Spacer()
        }
        .padding(.horizontal)
    }
}

struct MessageBubbleView: View {
    let message: ChatMessage
    let persona: UserPersona
    
    var body: some View {
        HStack {
            if message.isFromUser {
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(message.content)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(18)
                        .font(.body)
                    
                    Text(formatTime(message.timestamp))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: UIScreen.main.bounds.width * 0.75, alignment: .trailing)
            } else {
                HStack(alignment: .bottom, spacing: 8) {
                    AvatarView(persona: persona, size: 32)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(message.content)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(Color(.systemGray6))
                            .foregroundColor(.primary)
                            .cornerRadius(18)
                            .font(.body)
                        
                        Text(formatTime(message.timestamp))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: UIScreen.main.bounds.width * 0.75, alignment: .leading)
                    
                    Spacer()
                }
            }
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Error Types

enum ChatInitializationError: LocalizedError {
    case invalidPersona
    case viewModelNotReady
    case timeout
    
    var errorDescription: String? {
        switch self {
        case .invalidPersona:
            return "There's an issue with persona settings"
        case .viewModelNotReady:
            return "Chat is not ready"
        case .timeout:
            return "Initialization timed out"
        }
    }
}

// MARK: - Preview

struct ChatView_Previews: PreviewProvider {
    static var previews: some View {
        ChatView(isAIMode: true, persona: UserPersona.defaultPersona)
    }
}
