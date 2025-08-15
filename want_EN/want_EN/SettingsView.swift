import SwiftUI

struct SettingsView: View {
    @StateObject private var aiConfigManager = AIConfigManager.shared
    @StateObject private var personaManager = PersonaManager.shared
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @State private var showingAISettings = false
    @State private var showingAbout = false
    @State private var showingDataExport = false
    @State private var serverValidationEnabled = true
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 0) {
                    // AI Settings Section
                    VStack(alignment: .leading, spacing: 0) {
                        Text("AI Features")
                            .font(.headline)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                            .padding(.top, 20)
                            .padding(.bottom, 8)
                        
                        VStack(spacing: 0) {
                            NavigationLink(destination: AISettingsView()) {
                                HStack {
                                    Image(systemName: "brain.head.profile")
                                        .foregroundColor(.blue)
                                        .frame(width: 24)
                                    
                                    VStack(alignment: .leading) {
                                        Text("AI Settings")
                                            .font(.body)
                                        
                                        Text(aiConfigManager.currentConfig.isAIEnabled ? "Enabled" : "Disabled")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.secondary)
                                        .font(.caption)
                                }
                                .padding()
                                .background(Color(.systemBackground))
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            Divider()
                                .padding(.leading, 56)
                        }
                    }
                    
                    // Subscription Section
                    VStack(alignment: .leading, spacing: 0) {
                        Text("Subscription")
                            .font(.headline)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                            .padding(.top, 20)
                            .padding(.bottom, 8)
                        
                        VStack(spacing: 0) {
                            HStack {
                                Image(systemName: "creditcard")
                                    .foregroundColor(.green)
                                    .frame(width: 24)
                                
                                VStack(alignment: .leading) {
                                    Text("Current Status")
                                        .font(.body)
                                    
                                    Text(subscriptionManager.subscriptionStatus.displayName)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                            }
                            .padding()
                            .background(Color(.systemBackground))
                            
                            Divider()
                                .padding(.leading, 56)
                            
                            Button(action: {
                                Task {
                                    await subscriptionManager.restorePurchases()
                                }
                            }) {
                                HStack {
                                    Image(systemName: "arrow.clockwise")
                                        .foregroundColor(.blue)
                                        .frame(width: 24)
                                    
                                    Text("Restore Purchases")
                                        .foregroundColor(.primary)
                                    
                                    Spacer()
                                }
                                .padding()
                                .background(Color(.systemBackground))
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            Divider()
                                .padding(.leading, 56)
                        }
                    }
                    
                    // App Information Section
                    VStack(alignment: .leading, spacing: 0) {
                        Text("App Information")
                            .font(.headline)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                            .padding(.top, 20)
                            .padding(.bottom, 8)
                        
                        VStack(spacing: 0) {
                            HStack {
                                Image(systemName: "info.circle")
                                    .foregroundColor(.blue)
                                    .frame(width: 24)
                                
                                VStack(alignment: .leading) {
                                    Text("Version")
                                        .font(.body)
                                    
                                    Text("1.0.3")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                            }
                            .padding()
                            .background(Color(.systemBackground))
                            
                            Divider()
                                .padding(.leading, 56)
                            
                            Button(action: {
                                showingAbout = true
                            }) {
                                HStack {
                                    Image(systemName: "questionmark.circle")
                                        .foregroundColor(.blue)
                                        .frame(width: 24)
                                    
                                    Text("About This App")
                                        .foregroundColor(.primary)
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.secondary)
                                        .font(.caption)
                                }
                                .padding()
                                .background(Color(.systemBackground))
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            Divider()
                                .padding(.leading, 56)
                        }
                    }
                    
                    // Statistics Section
                    VStack(alignment: .leading, spacing: 0) {
                        Text("Statistics")
                            .font(.headline)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                            .padding(.top, 20)
                            .padding(.bottom, 8)
                        
                        VStack(spacing: 0) {
                            HStack {
                                Image(systemName: "person.2")
                                    .foregroundColor(.purple)
                                    .frame(width: 24)
                                
                                VStack(alignment: .leading) {
                                    Text("Created Personas")
                                        .font(.body)
                                    
                                    Text("\(personaManager.personas.count) people")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                            }
                            .padding()
                            .background(Color(.systemBackground))
                            
                            Divider()
                                .padding(.leading, 56)
                        }
                    }
                }
            }
            .navigationTitle("Settings")
        }
        .sheet(isPresented: $showingAbout) {
            AboutView()
        }
        .navigationBarTitleDisplayMode(.large)
        .ignoresSafeArea(.all, edges: .all)
    }
}

struct AboutView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    Image(systemName: "bubble.left.and.bubble.right.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.blue)
                    
                    Text("want")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Version 1.0.3")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    VStack(spacing: 16) {
                        Text("want is an app that lets you enjoy conversations with your own special people.")
                            .multilineTextAlignment(.center)
                        
                        Text("Create family, friends, lovers, and people with various relationships to experience conversations with unique personalities.")
                            .multilineTextAlignment(.center)
                    }
                    .font(.body)
                    .foregroundColor(.primary)
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("About This App")
            .navigationBarItems(
                trailing: Button("Done") {
                    dismiss()
                }
            )
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
