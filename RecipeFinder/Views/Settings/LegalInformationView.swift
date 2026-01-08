//
//  LegalInformationView.swift
//  RecipeFinder
//
//  Created by RecipeFinder on 5 November 2025.
//

import SwiftUI
import PDFKit

struct LegalInformationView: View {
    @Environment(\.colorScheme) var colorScheme
    @AppStorage("appTheme") private var selectedTheme: AppTheme.ThemeType = .teal
    @AppStorage("cardStyle") private var cardStyle: CardStyle = .frosted
    @State private var showPrivacyPolicy = false
    @State private var showTermsOfService = false
    @State private var showCompanyCompliance = false
    
    private let currentDateFormatted: String = {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMMM yyyy"
        return formatter.string(from: Date())
    }()
    
    var body: some View {
        ZStack {
            AppTheme.backgroundGradient(for: selectedTheme, colorScheme: colorScheme)
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: AppTheme.spacingXXL) {
                    // Company Information Header
                    SettingsCard {
                        VStack(alignment: .leading, spacing: AppTheme.spacingLG) {
                            HStack {
                                Image(systemName: "building.2.fill")
                                    .font(.title2)
                                    .adaptiveForegroundColor()
                                
                                Text("Company Information")
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                    .adaptiveForegroundColor()
                            }
                            
                            Divider()
                                .padding(.vertical, 4)
                            
                            CompanyInfoRow(label: "Legal Name", value: "RECIPEFINDER LIMITED")
                            CompanyInfoRow(label: "Company Number", value: "16833243")
                            CompanyInfoRow(label: "Registered", value: "England and Wales")
                            CompanyInfoRow(label: "Incorporation Date", value: "5 November 2025")
                            CompanyInfoRow(label: "Company Type", value: "Private Limited Company")
                            CompanyInfoRow(label: "Status", value: "Active", valueColor: colorScheme == .dark ? .green : Color(red: 0.0, green: 0.6, blue: 0.0))
                        }
                        .padding(AppTheme.spacingXL)
                    }
                    
                    // Contact Information
                    SettingsCard {
                        VStack(alignment: .leading, spacing: AppTheme.spacingLG) {
                            HStack {
                                Image(systemName: "envelope.fill")
                                    .font(.title2)
                                    .adaptiveForegroundColor()
                                
                                Text("Contact Information")
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                    .adaptiveForegroundColor()
                            }
                            
                            Divider()
                                .padding(.vertical, 4)
                            
                            Button(action: {
                                if let url = URL(string: "mailto:recipefinderlimited@icloud.com") {
                                    UIApplication.shared.open(url)
                                }
                            }) {
                                HStack(spacing: AppTheme.spacingMD) {
                                    Image(systemName: "envelope.circle.fill")
                                        .adaptiveForegroundColor()
                                        .font(.title3)
                                    
                                    VStack(alignment: .leading, spacing: AppTheme.spacingXS) {
                                        Text("Company Email")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        Text("recipefinderlimited@icloud.com")
                                            .font(.subheadline)
                                            .adaptiveForegroundColor()
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: "arrow.up.right.square")
                                        .foregroundColor(.secondary)
                                        .font(.caption)
                                }
                                .padding(AppTheme.spacingMD)
                                .background(Color.white.opacity(colorScheme == .dark ? AppTheme.dividerOpacity : 0.05))
                                .cornerRadius(10)
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            Button(action: {
                                if let url = URL(string: "https://recipefinder.uk") {
                                    UIApplication.shared.open(url)
                                }
                            }) {
                                HStack(spacing: AppTheme.spacingMD) {
                                    Image(systemName: "globe")
                                        .adaptiveForegroundColor()
                                        .font(.title3)
                                    
                                    VStack(alignment: .leading, spacing: AppTheme.spacingXS) {
                                        Text("Website")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        Text("recipefinder.uk")
                                            .font(.subheadline)
                                            .adaptiveForegroundColor()
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: "arrow.up.right.square")
                                        .foregroundColor(.secondary)
                                        .font(.caption)
                                }
                                .padding(AppTheme.spacingMD)
                                .background(Color.white.opacity(colorScheme == .dark ? AppTheme.dividerOpacity : 0.05))
                                .cornerRadius(10)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        .padding(AppTheme.spacingXL)
                    }
                    
                    // Legal Documents
                    SettingsCard {
                        VStack(spacing: 0) {
                            Button(action: {
                                showPrivacyPolicy = true
                                HapticManager.shared.light()
                            }) {
                                LegalDocRow(
                                    icon: "hand.raised.fill",
                                    iconColor: AppTheme.textColor(for: colorScheme),
                                    title: "Privacy Policy",
                                    subtitle: "How we handle your data"
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            Divider()
                                .padding(.leading, 62)
                            
                            Button(action: {
                                showTermsOfService = true
                                HapticManager.shared.light()
                            }) {
                                LegalDocRow(
                                    icon: "doc.text.fill",
                                    iconColor: AppTheme.textColor(for: colorScheme),
                                    title: "Terms of Service",
                                    subtitle: "Terms and conditions of use"
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            Divider()
                                .padding(.leading, 62)
                            
                            Button(action: {
                                showCompanyCompliance = true
                                HapticManager.shared.light()
                            }) {
                                LegalDocRow(
                                    icon: "checkmark.shield.fill",
                                    iconColor: AppTheme.textColor(for: colorScheme),
                                    title: "UK Company Compliance",
                                    subtitle: "Companies Act 2006 compliance"
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    
                    // Compliance Badges
                    SettingsCard {
                        VStack(alignment: .leading, spacing: AppTheme.spacingLG) {
                            HStack {
                                Image(systemName: "shield.checkered")
                                    .font(.title2)
                                    .adaptiveForegroundColor()
                                
                                Text("Regulatory Compliance")
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                    .adaptiveForegroundColor()
                            }
                            
                            Divider()
                                .padding(.vertical, 4)
                            
                            ComplianceBadge(
                                icon: "checkmark.seal.fill",
                                title: "UK GDPR",
                                description: "Compliant with UK General Data Protection Regulation",
                                color: AppTheme.textColor(for: colorScheme)
                            )
                            
                            ComplianceBadge(
                                icon: "lock.shield.fill",
                                title: "Data Protection Act 2018",
                                description: "Adherence to UK data protection legislation",
                                color: AppTheme.textColor(for: colorScheme)
                            )
                            
                            ComplianceBadge(
                                icon: "building.columns.fill",
                                title: "Companies Act 2006",
                                description: "Registered and compliant with UK company law",
                                color: AppTheme.textColor(for: colorScheme)
                            )
                            
                            ComplianceBadge(
                                icon: "doc.text.fill",
                                title: "Companies House",
                                description: "Active registration in England and Wales",
                                color: AppTheme.textColor(for: colorScheme)
                            )
                        }
                        .padding(AppTheme.spacingXL)
                    }
                    
                    // Director Information
                    SettingsCard {
                        VStack(alignment: .leading, spacing: AppTheme.spacingLG) {
                            HStack {
                                Image(systemName: "person.crop.circle.badge.checkmark")
                                    .font(.title2)
                                    .adaptiveForegroundColor()
                                
                                Text("Company Directors")
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                    .adaptiveForegroundColor()
                            }
                            
                            Divider()
                                .padding(.vertical, 4)
                            
                            VStack(alignment: .leading, spacing: AppTheme.spacingSM) {
                                Text("Asad Khan")
                                    .font(.headline)
                                    .adaptiveForegroundColor()
                                
                                Label("Director", systemImage: "briefcase.fill")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Label("Appointed: 5 November 2025", systemImage: "calendar")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(AppTheme.spacingMD)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.white.opacity(colorScheme == .dark ? AppTheme.dividerOpacity : 0.05))
                            .cornerRadius(10)
                        }
                        .padding(AppTheme.spacingXL)
                    }
                    
                    // App Version Info
                    VStack(spacing: AppTheme.spacingXS) {
                        Text("RecipeFinder")
                            .font(.caption)
                            .foregroundColor(.white.opacity(AppTheme.mediumEmphasisOpacity))
                        Text("Version 1.0.0 (Build 1)")
                            .font(.caption2)
                            .foregroundColor(.white.opacity(AppTheme.glassLightOpacity))
                        Text("© 2025 RECIPEFINDER LIMITED")
                            .font(.caption2)
                            .foregroundColor(.white.opacity(AppTheme.glassLightOpacity))
                    }
                    .padding(.top, 24)
                    .padding(.bottom, 40)
                }
                .padding(AppTheme.spacingXL)
            }
        }
        .navigationTitle("Legal Information")
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .sheet(isPresented: $showPrivacyPolicy) {
            PrivacyPolicyView()
        }
        .sheet(isPresented: $showTermsOfService) {
            TermsOfServiceView()
        }
        .sheet(isPresented: $showCompanyCompliance) {
            CompanyComplianceView()
        }
    }
}

// MARK: - Supporting Views

struct CompanyInfoRow: View {
    let label: String
    let value: String
    var valueColor: Color = .primary
    
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack(alignment: .top) {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .frame(width: 140, alignment: .leading)
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(valueColor == .primary ? AppTheme.textColor(for: colorScheme) : valueColor)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 4)
    }
}

struct LegalDocRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack(spacing: AppTheme.spacingMD) {
            Image(systemName: icon)
                .foregroundColor(iconColor)
                .font(.title3)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: AppTheme.spacingXXS) {
                Text(title)
                    .font(.subheadline)
                    .adaptiveForegroundColor()
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding(AppTheme.spacingXL)
    }
}

struct ComplianceBadge: View {
    let icon: String
    let title: String
    let description: String
    let color: Color
    
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack(alignment: .top, spacing: AppTheme.spacingMD) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 40, height: 40)
                
                Image(systemName: icon)
                    .font(.system(size: AppTheme.fontSizeBody + 2, weight: .semibold))
                    .foregroundColor(color)
            }
            
            VStack(alignment: .leading, spacing: AppTheme.spacingXS) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .adaptiveForegroundColor()
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - PDF Viewer

struct PDFViewerSheet: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    let title: String
    let pdfName: String
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(UIColor.systemBackground)
                    .ignoresSafeArea()
                
                if let pdfURL = Bundle.main.url(forResource: pdfName, withExtension: "pdf") {
                    PDFKitView(url: pdfURL)
                        .ignoresSafeArea(edges: .bottom)
                } else {
                    VStack(spacing: AppTheme.spacingLG) {
                        Image(systemName: "doc.text.fill")
                            .font(.system(size: AppTheme.fontSizeDisplay))
                            .foregroundColor(.red)
                        
                        Text("PDF Not Found")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("Unable to locate \(pdfName).pdf")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
                
                if Bundle.main.url(forResource: pdfName, withExtension: "pdf") != nil {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            sharePDF()
                        }) {
                            Image(systemName: "square.and.arrow.up")
                        }
                    }
                }
            }
        }
    }
    
    private func sharePDF() {
        guard let pdfURL = Bundle.main.url(forResource: pdfName, withExtension: "pdf") else { return }
        
        let activityVC = UIActivityViewController(
            activityItems: [pdfURL],
            applicationActivities: nil
        )
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootVC = window.rootViewController {
            
            // For iPad
            if let popover = activityVC.popoverPresentationController {
                popover.sourceView = window
                popover.sourceRect = CGRect(x: window.bounds.midX, y: window.bounds.midY, width: 0, height: 0)
                popover.permittedArrowDirections = []
            }
            
            rootVC.present(activityVC, animated: true)
        }
    }
}

struct PDFKitView: UIViewRepresentable {
    let url: URL
    
    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = .vertical
        
        if let document = PDFDocument(url: url) {
            pdfView.document = document
        }
        
        return pdfView
    }
    
    func updateUIView(_ pdfView: PDFView, context: Context) {
        // No updates needed
    }
}

// MARK: - Document Views

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
                    VStack(alignment: .leading, spacing: AppTheme.spacingXL) {
                        Group {
                            Text("Privacy Policy")
                                .font(.system(size: AppTheme.fontSizeMedium, weight: .bold))
                                .adaptiveForegroundColor()
                            
                            Text("Last Updated: \(currentDateFormatted)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Divider()
                            
                            SectionTitle("1. Interpretation and Definitions")
                            
                            BodyText("1.1 In this Privacy Policy:")
                            BulletPoint("\"Company\", \"we\", \"us\" or \"our\" means RECIPEFINDER LIMITED (company number 16833243), a private limited company registered in England and Wales.")
                            BulletPoint("\"Application\" means the RecipeFinder mobile application software.")
                            BulletPoint("\"User\", \"you\" or \"your\" means the individual accessing or using the Application.")
                            BulletPoint("\"Personal Information\" means any information relating to an identified or identifiable natural person.")
                            BulletPoint("\"Device\" means any device that can access the Application, such as an iPhone or iPad.")
                            
                            SectionTitle("2. Information Collection and Processing")
                            
                            BodyText("2.1 The Company does not collect, process, store or transmit any Personal Information through the Application.")
                            
                            BodyText("2.2 The Application operates on a local-only basis. All data generated through your use of the Application is stored exclusively on your Device using Core Data and UserDefaults frameworks.")
                            
                            BodyText("2.3 Data stored locally on your Device includes, without limitation:")
                            BulletPoint("Recipe data (including imported recipes)")
                            BulletPoint("Shopping list items")
                            BulletPoint("Kitchen inventory records")
                            BulletPoint("Meal planning information")
                            BulletPoint("User preferences and settings")
                            BulletPoint("Favorited items")
                            
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
                            BulletPoint("Export all data via the Account section of the Application")
                            BulletPoint("Delete all data via Settings > Data Management")
                            BulletPoint("Remove all data by uninstalling the Application from your Device")
                        }
                        
                        Group {
                            SectionTitle("6. Compliance with Data Protection Laws")
                            
                            BodyText("6.1 The Application is designed to comply with:")
                            BulletPoint("UK General Data Protection Regulation (UK GDPR)")
                            BulletPoint("Data Protection Act 2018")
                            BulletPoint("Children's Online Privacy Protection Act (COPPA)")
                            
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
                    .padding(AppTheme.spacingXXL)
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

struct TermsOfServiceView: View {
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
                    VStack(alignment: .leading, spacing: AppTheme.spacingXL) {
                        Group {
                            Text("Terms of Service")
                                .font(.system(size: AppTheme.fontSizeMedium, weight: .bold))
                                .adaptiveForegroundColor()
                            
                            Text("Last Updated: \(currentDateFormatted)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Divider()
                            
                            SectionTitle("1. Interpretation and General")
                            
                            BodyText("1.1 Definitions. In these Terms:")
                            BulletPoint("\"Company\" means RECIPEFINDER LIMITED (company number 16833243).")
                            BulletPoint("\"Application\" means the RecipeFinder mobile application and associated website located at recipefinder.uk.")
                            BulletPoint("\"User\" or \"you\" means any person who accesses, downloads, installs or uses the Application.")
                            BulletPoint("\"Terms\" means these Terms of Service, as amended from time to time.")
                            
                            BodyText("1.2 Acceptance. By accessing or using the Application, you agree to be bound by these Terms. If you do not agree to these Terms, you must not use the Application.")
                            
                            SectionTitle("2. Scope of Service")
                            
                            BodyText("2.1 The Application provides recipe discovery, import, organization and related recipe management features. The Company may modify, suspend or discontinue the Application (or any part thereof) at any time.")
                            
                            SectionTitle("3. User Accounts and Access")
                            
                            BodyText("3.1 Account creation is not required to use the Application. All data is stored locally on your device.")
                            
                            SectionTitle("4. Acceptable Use")
                            
                            BodyText("4.1 You shall not:")
                            BulletPoint("use the Application in violation of applicable law;")
                            BulletPoint("infringe the intellectual property or other rights of third parties;")
                            BulletPoint("attempt to gain unauthorised access to any systems or data;")
                            BulletPoint("introduce viruses, malware, or other harmful code; or")
                            BulletPoint("use the Application for any unlawful or abusive purpose.")
                        }
                        
                        Group {
                            SectionTitle("5. Intellectual Property")
                            
                            BodyText("5.1 All intellectual property rights in and to the Application and its content (including software, logos and trademarks) are owned by the Company or its licensors. Nothing in these Terms grants you any rights to the Company's intellectual property except as expressly set out in these Terms.")
                            
                            SectionTitle("6. User Content")
                            
                            BodyText("6.1 You retain ownership of content you submit to the Application. By submitting content you grant the Company a non-exclusive, worldwide, royalty-free licence to use, reproduce and display such content for the purposes of operating and providing the Application.")
                            
                            BodyText("6.2 When importing recipes from third-party websites, you are responsible for ensuring compliance with applicable copyright laws and terms of use of such websites.")
                            
                            SectionTitle("7. Warranty Disclaimer")
                            
                            BodyText("7.1 The Application is provided \"as is\" and the Company expressly disclaims all warranties, whether express or implied, including warranties of merchantability, fitness for a particular purpose and non-infringement.")
                            
                            BodyText("7.2 The Company does not warrant the accuracy, completeness or safety of any recipes or cooking instructions displayed in the Application. You are solely responsible for verifying recipe information and food safety.")
                        }
                        
                        Group {
                            SectionTitle("8. Limitation of Liability")
                            
                            BodyText("8.1 To the maximum extent permitted by applicable law, the Company's total liability arising out of or in connection with these Terms shall be limited to the greater of £50 or the amount you have paid to the Company in the 12 months preceding the claim.")
                            
                            BodyText("8.2 The Company shall not be liable for any indirect, incidental, special, consequential or punitive damages, including without limitation loss of data, loss of profits or damage arising from food preparation.")
                            
                            SectionTitle("9. Third-Party Content and Links")
                            
                            BodyText("9.1 The Application may contain links to third-party websites or services. The Company is not responsible for the content or policies of such third parties, and your use of third-party services is at your own risk.")
                            
                            SectionTitle("10. Recipe Import and Data Handling")
                            
                            BodyText("10.1 When you elect to import a recipe by providing a URL, the Application will retrieve the content directly from the URL you supply. The Company does not intermediate or store copies of the source webpages on its servers. Parsed recipe data is stored locally on your device.")
                            
                            SectionTitle("11. Termination")
                            
                            BodyText("11.1 The Company may suspend or terminate your access to the Application immediately if you breach these Terms or where required by law.")
                        }
                        
                        Group {
                            SectionTitle("12. Governing Law and Jurisdiction")
                            
                            BodyText("12.1 These Terms shall be governed by and construed in accordance with the laws of England and Wales. The courts of England and Wales shall have exclusive jurisdiction to settle any dispute arising out of or in connection with these Terms.")
                            
                            SectionTitle("13. Amendments")
                            
                            BodyText("13.1 The Company may amend these Terms from time to time. Material changes will be notified through the Application or on the Company's website. Continued use of the Application following notice of changes constitutes acceptance of the updated Terms.")
                            
                            SectionTitle("14. Severability")
                            
                            BodyText("14.1 If any provision of these Terms is held to be invalid or unenforceable, the remaining provisions shall continue in full force and effect.")
                            
                            SectionTitle("15. Contact")
                            
                            BodyText("For enquiries regarding these Terms, you may contact:")
                            BodyText("RECIPEFINDER LIMITED")
                            BodyText("Company Number: 16833243")
                            BodyText("Registered in England and Wales")
                            BodyText("Director: Asad Khan")
                            BodyText("Email: recipefinderlimited@icloud.com")
                            BodyText("Website: recipefinder.uk")
                        }
                    }
                    .padding(AppTheme.spacingXXL)
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

struct CompanyComplianceView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    @AppStorage("appTheme") private var selectedTheme: AppTheme.ThemeType = .teal
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.backgroundGradient(for: selectedTheme, colorScheme: colorScheme)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: AppTheme.spacingXL) {
                        Group {
                            Text("UK Company Compliance")
                                .font(.system(size: AppTheme.fontSizeMedium, weight: .bold))
                                .adaptiveForegroundColor()
                            
                            Text("Companies Act 2006")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Divider()
                            
                            SectionTitle("1. Company Registration Details")
                            CompanyDetailRow(label: "Legal Name", value: "RECIPEFINDER LIMITED")
                            CompanyDetailRow(label: "Company Number", value: "16833243")
                            CompanyDetailRow(label: "Jurisdiction", value: "England and Wales")
                            CompanyDetailRow(label: "Incorporation Date", value: "5 November 2025")
                            CompanyDetailRow(label: "Company Type", value: "Private Limited Company")
                            CompanyDetailRow(label: "Status", value: "Active")
                        }
                        
                        Group {
                            SectionTitle("2. Directors")
                            BodyText("The Company's current director is:")
                            BodyText("Name: Asad Khan")
                            BodyText("Appointed: 5 November 2025")
                            
                            SectionTitle("3. Director Responsibilities")
                            BodyText("3.1 Under Sections 171-177 of the Companies Act 2006, directors have the following statutory duties:")
                            BulletPoint("Section 171: Duty to act within powers")
                            BulletPoint("Section 172: Duty to promote the success of the company")
                            BulletPoint("Section 173: Duty to exercise independent judgment")
                            BulletPoint("Section 174: Duty to exercise reasonable care, skill and diligence")
                            BulletPoint("Section 175: Duty to avoid conflicts of interest")
                            BulletPoint("Section 176: Duty not to accept benefits from third parties")
                            BulletPoint("Section 177: Duty to declare interest in proposed transaction or arrangement")
                        }
                        
                        Group {
                            SectionTitle("4. Regulatory Compliance")
                            BodyText("4.1 The Company maintains compliance with:")
                            BulletPoint("Companies Act 2006 (United Kingdom)")
                            BulletPoint("UK General Data Protection Regulation (UK GDPR)")
                            BulletPoint("Data Protection Act 2018")
                            BulletPoint("Copyright, Designs and Patents Act 1988")
                            BulletPoint("Consumer Rights Act 2015")
                            
                            SectionTitle("5. Registered Office")
                            BodyText("5.1 The Company's registered office address is maintained on file with Companies House in accordance with Section 86 of the Companies Act 2006.")
                            
                            SectionTitle("6. Annual Requirements")
                            BodyText("6.1 The Company shall comply with all annual filing requirements, including:")
                            BulletPoint("Confirmation Statement (Section 853A)")
                            BulletPoint("Annual Accounts (Sections 441-442)")
                            BulletPoint("Corporation Tax Return (as required by HMRC)")
                        }
                        
                        Group {
                            SectionTitle("7. Public Records")
                            BodyText("7.1 Full company records, including current and historical filings, may be accessed through Companies House using company number 16833243.")
                            
                            BodyText("7.2 Companies House website: www.gov.uk/companieshouse")
                            
                            SectionTitle("8. Contact for Company Matters")
                            BodyText("For official company correspondence:")
                            BodyText("RECIPEFINDER LIMITED")
                            BodyText("Company Number: 16833243")
                            BodyText("Email: recipefinderlimited@icloud.com")
                        }
                    }
                    .padding(AppTheme.spacingXXL)
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

// MARK: - Text Styling Views

struct SectionTitle: View {
    let text: String
    @Environment(\.colorScheme) var colorScheme
    
    init(_ text: String) {
        self.text = text
    }
    
    var body: some View {
        Text(text)
            .font(.title3)
            .fontWeight(.bold)
            .adaptiveForegroundColor()
            .padding(.top, 8)
    }
}

struct BodyText: View {
    let text: String
    @Environment(\.colorScheme) var colorScheme
    
    init(_ text: String) {
        self.text = text
    }
    
    var body: some View {
        Text(text)
            .font(.body)
            .foregroundColor(colorScheme == .dark ? .white.opacity(AppTheme.cardLightOpacity) : .black.opacity(AppTheme.highEmphasisOpacity))
            .fixedSize(horizontal: false, vertical: true)
    }
}

private struct BulletPoint: View {
    let text: String
    @Environment(\.colorScheme) var colorScheme
    
    init(_ text: String) {
        self.text = text
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: AppTheme.spacingSM) {
            Text("•")
                .foregroundColor(.secondary)
            Text(text)
                .font(.body)
                .foregroundColor(colorScheme == .dark ? .white.opacity(AppTheme.cardLightOpacity) : .black.opacity(AppTheme.highEmphasisOpacity))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.leading, 8)
    }
}

struct CompanyDetailRow: View {
    let label: String
    let value: String
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack {
            Text(label + ":")
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .adaptiveForegroundColor()
        }
        .padding(.vertical, 2)
    }
}

#Preview {
    NavigationStack {
        LegalInformationView()
    }
}
