import SwiftUI

struct PrivacyPolicyView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    @AppStorage("appTheme") private var selectedTheme: AppTheme.ThemeType = .teal
    
    private let currentDateFormatted: String = {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMMM yyyy"
        return formatter.string(from: Date())
    }()
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.backgroundGradient(for: selectedTheme, colorScheme: colorScheme)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: AppTheme.spacing24) {
                        Group {
                            Text("Privacy Policy")
                                .font(.system(size: AppTheme.fontSize32, weight: .bold))
                                .adaptiveForegroundColor()
                            
                            Text("Last Updated: \(currentDateFormatted)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Divider()
                            
                            SectionTitle("1. Interpretation and Definitions")
                            
                            BodyText("1.1 In this Privacy Policy:")
                            LegalBulletPoint("\"Company\", \"we\", \"us\" or \"our\" means RECIPEFINDER LIMITED (company number 16833243), a private limited company registered in England and Wales.")
                            LegalBulletPoint("\"Application\" means the RecipeFinder mobile application software.")
                            LegalBulletPoint("\"User\", \"you\" or \"your\" means the individual accessing or using the Application.")
                            LegalBulletPoint("\"Personal Information\" means any information relating to an identified or identifiable natural person.")
                            LegalBulletPoint("\"Device\" means any device that can access the Application, such as an iPhone or iPad.")
                            
                            SectionTitle("2. Information Collection and Processing")
                            
                            BodyText("2.1 The Company does not collect, process, store or transmit any Personal Information through the Application.")
                            
                            BodyText("2.2 The Application operates on a local-only basis. All data generated through your use of the Application is stored exclusively on your Device using Core Data and UserDefaults frameworks.")
                            
                            BodyText("2.3 Data stored locally on your Device includes, without limitation:")
                            LegalBulletPoint("Recipe data (including imported recipes)")
                            LegalBulletPoint("Shopping list items")
                            LegalBulletPoint("Kitchen inventory records")
                            LegalBulletPoint("Meal planning information")
                            LegalBulletPoint("User preferences and settings")
                            LegalBulletPoint("Favorited items")
                            
                            BodyText("2.4 No user accounts, registrations or authentication mechanisms are required to use the Application.")
                        }
                        
                        Group {
                            SectionTitle("3. Third-Party Services and Analytics")
                            
                            BodyText("3.1 The Application does not integrate with any third-party analytics services, advertising networks or tracking systems.")
                            
                            BodyText("3.2 When you elect to import a recipe by providing a URL, the Application retrieves content directly from the URL you supply. The Company does not intermediate, store copies of or monitor such requests.")
                            
                            SectionTitle("4. Data Security")
                            
                            BodyText("4.1 As all data remains on your Device and is not transmitted to the Company's servers or any third party, data security is primarily dependent on your Device's security measures.")
                            
                            BodyText("4.2 The Company recommends that you maintain appropriate security measures on your Device, including but not limited to password protection and device encryption.")
                            
                            SectionTitle("5. Your Rights and Control")
                            
                            BodyText("5.1 You retain complete control over all data stored by the Application on your Device.")
                            
                            BodyText("5.2 You may at any time:")
                            LegalBulletPoint("Export all data via the Account section of the Application")
                            LegalBulletPoint("Delete all data via Settings > Data Management")
                            LegalBulletPoint("Remove all data by uninstalling the Application from your Device")
                        }
                        
                        Group {
                            SectionTitle("6. Compliance with Data Protection Laws")
                            
                            BodyText("6.1 The Application is designed to comply with:")
                            LegalBulletPoint("UK General Data Protection Regulation (UK GDPR)")
                            LegalBulletPoint("Data Protection Act 2018")
                            LegalBulletPoint("Children's Online Privacy Protection Act (COPPA)")
                            
                            BodyText("6.2 Given that the Company does not collect or process any Personal Information, the majority of data protection obligations under these laws do not apply.")
                            
                            SectionTitle("7. Children's Privacy")
                            
                            BodyText("7.1 The Application may be used by individuals under the age of 13. As no Personal Information is collected, parental consent is not required.")
                            
                            SectionTitle("8. Changes to This Privacy Policy")
                            
                            BodyText("8.1 The Company reserves the right to amend this Privacy Policy at any time. The date of the most recent revision shall be indicated at the top of this Privacy Policy.")
                            
                            BodyText("8.2 Material changes shall be notified through the Application. Continued use of the Application following notification constitutes acceptance of the amended Privacy Policy.")
                            
                            SectionTitle("9. Contact Information")
                            
                            BodyText("9.1 For enquiries regarding this Privacy Policy, you may contact:")
                            BodyText("RECIPEFINDER LIMITED")
                            BodyText("Company Number: 16833243")
                            BodyText("Email: recipefinderlimited@icloud.com")
                            BodyText("Website: recipefinder.uk")
                        }
                    }
                    .padding(AppTheme.spacing32)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}
