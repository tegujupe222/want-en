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
            .navigationTitle("Import Chat History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("How to Use") {
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
            .alert("Error", isPresented: .constant(lineAnalyzer.errorMessage != nil)) {
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
            // Header
            VStack(spacing: 16) {
                Image(systemName: "doc.text.magnifyingglass")
                    .font(.system(size: 60))
                    .foregroundColor(.accentColor)
                
                Text("Analyze LINE Chat History")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Automatically analyze speaking style and\npersonality from chat history")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            // Import button
            VStack(spacing: 16) {
                importButton
                
                // Drag & drop area
                dropArea
            }
            
            Spacer()
        }
    }
    
    private var importButton: some View {
        Button(action: {
            showingFilePicker = true
        }) {
            Text("Select File")
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
            Text("Drag & drop files here")
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
            
            // Progress animation
            VStack(spacing: 16) {
                loadingIndicator
                
                Text("Analyzing chat history...")
                    .font(.headline)
                
                Text("Automatically extracting speaking style\nand personality characteristics")
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
                // Header
                VStack(spacing: 8) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.title2)
                        Text("Analysis Complete!")
                            .font(.title2)
                            .fontWeight(.bold)
                    }
                    
                    Text("The following characteristics were detected")
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.bottom)
                
                // Analysis results
                VStack(alignment: .leading, spacing: 16) {
                    ResultCard(
                        title: "Detected Name",
                        content: result.detectedName,
                        icon: "person.circle"
                    )
                    
                    ResultCard(
                        title: "Speaking Style",
                        content: result.communicationStyle,
                        icon: "bubble.left"
                    )
                    
                    ResultCard(
                        title: "Personality",
                        content: result.personality.joined(separator: ", "),
                        icon: "heart"
                    )
                    
                    ResultCard(
                        title: "Common Phrases",
                        content: result.commonPhrases.prefix(5).joined(separator: ", "),
                        icon: "quote.bubble"
                    )
                    
                    ResultCard(
                        title: "Topics",
                        content: result.favoriteTopics.joined(separator: ", "),
                        icon: "bubble.left.and.bubble.right"
                    )
                    
                    ResultCard(
                        title: "Relationship",
                        content: result.messageFrequency,
                        icon: "person.2"
                    )
                }
                
                // Apply button
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
                        Text("Apply This Setting")
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
                lineAnalyzer.errorMessage = "Failed to load file: \(error.localizedDescription)"
            }
            
        case .failure(let error):
            lineAnalyzer.errorMessage = "Failed to select file: \(error.localizedDescription)"
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
            
            Text(content.isEmpty ? "Not detected" : content)
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
                    // LINE export instructions
                    InstructionSection(
                        title: "How to Export LINE Chat History",
                        icon: "1.circle.fill",
                        steps: [
                            "Open the target chat room in LINE app",
                            "Tap the menu (☰) in the top right",
                            "Select \"Other\" → \"Send Chat History\"",
                            "Choose \"Text File\"",
                            "Save the file with \"Save to File\""
                        ]
                    )
                    
                    Divider()
                    
                    // Notes
                    InstructionSection(
                        title: "Notes",
                        icon: "exclamationmark.triangle.fill",
                        steps: [
                            "For privacy protection, analysis is performed on-device",
                            "Files are automatically deleted after analysis",
                            "Personal information is not sent externally",
                            "Large files may take time to analyze"
                        ]
                    )
                    
                    Divider()
                    
                    // Analysis content
                    InstructionSection(
                        title: "What Gets Analyzed",
                        icon: "chart.bar.fill",
                        steps: [
                            "Speaking style characteristics (polite language usage, emoji frequency, etc.)",
                            "Common phrases and catchphrases",
                            "Personality tendencies (kindness, cheerfulness, etc.)",
                            "Frequent topics of conversation",
                            "Communication frequency"
                        ]
                    )
                }
                .padding()
            }
            .navigationTitle("How to Use")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
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
