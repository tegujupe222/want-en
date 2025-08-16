import SwiftUI

struct LegalView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTab = 0
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Tab selection
                Picker("Legal Document", selection: $selectedTab) {
                    Text("Terms of Service").tag(0)
                    Text("Privacy Policy").tag(1)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                // Content display
                TabView(selection: $selectedTab) {
                    EULAView()
                        .tag(0)
                    
                    PrivacyPolicyView()
                        .tag(1)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            }
            .navigationTitle("Legal Documents")
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

struct EULAView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Terms of Service (EULA)")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Last updated: June 24, 2025")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Group {
                    Text("1. General Provisions")
                        .font(.headline)
                    Text("These Terms of Service (hereinafter \"Terms\") set forth the conditions for the use of the \"want\" application (hereinafter \"App\") provided by igafactory (hereinafter \"Company\").")
                    
                    Text("2. Acceptance of Terms")
                        .font(.headline)
                    Text("By downloading, installing, or using the App, users are deemed to have agreed to these Terms.")
                    
                    Text("3. Usage Period")
                        .font(.headline)
                    Text("The App is available for the following periods:\n• Free trial period: 3 days from first launch\n• Paid subscription period: Continuous use through monthly billing")
                    
                    Text("4. Usage Fees")
                        .font(.headline)
                    Text("• All features are available free of charge during the free trial period\n• After the trial period ends, a monthly subscription (price displayed in App Store) is required\n• Billing is processed through the App Store and follows Apple's billing system")
                    
                    Text("5. Prohibited Activities")
                        .font(.headline)
                    Text("Users must not engage in the following activities:\n• Reverse compilation, disassembly, or reverse engineering of the App\n• Infringement of copyright, trademark, or other intellectual property rights of the App\n• Illegal activities using the App\n• Actions that cause trouble to other users\n• Actions that place load on the App's servers or networks")
                    
                    Text("6. Privacy")
                        .font(.headline)
                    Text("The handling of user personal information is subject to the separate Privacy Policy.")
                    
                    Text("7. AI Features")
                        .font(.headline)
                    Text("The App uses Google Gemini API to provide AI features:\n• Conversations with AI are managed appropriately\n• Avoid entering confidential or personal information\n• AI responses are for reference only and should not be used for important decisions such as medical, legal, or investment matters")
                    
                    Text("8. Disclaimer")
                        .font(.headline)
                    Text("• The Company assumes no responsibility for any damages arising from the use of the App\n• App features may be changed without notice\n• The Company may provide technical support for issues arising from App use, but does not guarantee such support")
                    
                    Text("9. Changes to Terms")
                        .font(.headline)
                    Text("The Company may change these Terms as necessary. Changed terms will be notified within the App or on the Company's website.")
                    
                    Text("10. Governing Law and Jurisdiction")
                        .font(.headline)
                    Text("The interpretation and application of these Terms shall be governed by Japanese law, with the Tokyo District Court as the court of first instance with exclusive jurisdiction.")
                    
                    Text("Contact")
                        .font(.headline)
                    Text("For inquiries regarding these Terms, please contact:\n• Email: igafactory2023@gmail.com")
                }
            }
            .padding()
        }
    }
}

struct PrivacyPolicyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Privacy Policy")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Last updated: June 24, 2025")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Group {
                    Text("1. Information Collected")
                        .font(.headline)
                    Text("1.1 Automatically Collected Information\n• Device information (OS version, app version, etc.)\n• Usage statistics (app usage frequency, feature usage, etc.)\n• Crash reports\n\n1.2 Information Entered by Users\n• Conversation content with AI\n• Settings information (persona settings, emotion settings, etc.)\n• Subscription information (through App Store)")
                    
                    Text("2. Purpose of Information Use")
                        .font(.headline)
                    Text("Collected information is used for the following purposes:\n• Providing App functionality\n• Service improvement and development\n• Customer support\n• Prevention of unauthorized use\n• Compliance with legal obligations")
                    
                    Text("3. Information Sharing")
                        .font(.headline)
                    Text("The Company will not provide personal information to third parties except in the following cases:\n• When user consent is obtained\n• When required by law\n• When necessary to protect human life, body, or property\n• When particularly necessary for public health improvement or healthy child development")
                    
                    Text("4. Use of External Services")
                        .font(.headline)
                    Text("4.1 Google Gemini API\n• Used to provide AI features\n• Conversation content is sent to Google's servers\n• Google's Privacy Policy applies\n\n4.2 Apple App Store\n• Used for app distribution and billing\n• Apple's Privacy Policy applies")
                    
                    Text("5. Information Retention Period")
                        .font(.headline)
                    Text("• Conversation content: Locally stored in app (on device)\n• Settings information: Locally stored in app\n• Usage statistics: Permanently stored in anonymized form")
                    
                    Text("6. Information Security")
                        .font(.headline)
                    Text("The Company implements necessary and appropriate measures to prevent leakage, loss, or damage of personal information and for other security management of personal information.")
                    
                    Text("7. User Rights")
                        .font(.headline)
                    Text("Users have the following rights:\n• Request for disclosure of personal information\n• Request for correction, addition, or deletion of personal information\n• Request for suspension or deletion of personal information use")
                    
                    Text("8. Information from Minors")
                        .font(.headline)
                    Text("We do not collect personal information from users under 13 years of age. For users 13 years or older but under 18, we provide services after obtaining parental consent.")
                    
                    Text("9. Changes to Privacy Policy")
                        .font(.headline)
                    Text("The Company may change this Privacy Policy as necessary. For important changes, notification will be provided within the app or on the Company's website.")
                    
                    Text("10. Contact")
                        .font(.headline)
                    Text("For inquiries regarding personal information handling, please contact:\n\nEmail: igafactory2023@gmail.com\nResponse hours: Weekdays 9:00-18:00 (Japan time)\n\nPrivacy Policy details: https://tegujupe222.github.io/privacy-policy/")
                    
                    Text("11. Governing Law")
                        .font(.headline)
                    Text("This Privacy Policy is governed by Japanese law.")
                }
            }
            .padding()
        }
    }
}

#Preview {
    LegalView()
} 