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
    @State private var showCertificate = false
    
    var body: some View {
        ZStack {
            AppTheme.backgroundGradient(for: selectedTheme, colorScheme: colorScheme)
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Company Information Header
                    SettingsCard {
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Image(systemName: "building.2.fill")
                                    .font(.title2)
                                    .foregroundColor(AppTheme.accentColor(for: selectedTheme))
                                
                                Text("Company Information")
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                    .foregroundColor(colorScheme == .dark ? .white : .black)
                            }
                            
                            Divider()
                                .padding(.vertical, 4)
                            
                            CompanyInfoRow(label: "Legal Name", value: "RECIPEFINDER LIMITED")
                            CompanyInfoRow(label: "Company Number", value: "16833243")
                            CompanyInfoRow(label: "Registered", value: "England and Wales")
                            CompanyInfoRow(label: "Incorporation Date", value: "5 November 2025")
                            CompanyInfoRow(label: "Company Type", value: "Private Limited Company")
                            CompanyInfoRow(label: "Status", value: "Active", valueColor: .green)
                        }
                        .padding(20)
                    }
                    
                    // Contact Information
                    SettingsCard {
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Image(systemName: "envelope.fill")
                                    .font(.title2)
                                    .foregroundColor(.blue)
                                
                                Text("Contact Information")
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                    .foregroundColor(colorScheme == .dark ? .white : .black)
                            }
                            
                            Divider()
                                .padding(.vertical, 4)
                            
                            Button(action: {
                                if let url = URL(string: "mailto:AsadK47@users.noreply.github.com") {
                                    UIApplication.shared.open(url)
                                }
                            }) {
                                HStack(spacing: 12) {
                                    Image(systemName: "envelope.circle.fill")
                                        .foregroundColor(.blue)
                                        .font(.title3)
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Registered Email")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        Text("AsadK47@users.noreply.github.com")
                                            .font(.subheadline)
                                            .foregroundColor(colorScheme == .dark ? .white : .black)
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: "arrow.up.right.square")
                                        .foregroundColor(.secondary)
                                        .font(.caption)
                                }
                                .padding(12)
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(10)
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            Button(action: {
                                if let url = URL(string: "https://recipefinder.uk") {
                                    UIApplication.shared.open(url)
                                }
                            }) {
                                HStack(spacing: 12) {
                                    Image(systemName: "globe")
                                        .foregroundColor(.purple)
                                        .font(.title3)
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Website")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        Text("recipefinder.uk")
                                            .font(.subheadline)
                                            .foregroundColor(colorScheme == .dark ? .white : .black)
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: "arrow.up.right.square")
                                        .foregroundColor(.secondary)
                                        .font(.caption)
                                }
                                .padding(12)
                                .background(Color.purple.opacity(0.1))
                                .cornerRadius(10)
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            Button(action: {
                                if let url = URL(string: "https://github.com/AsadK47/RecipeFinder") {
                                    UIApplication.shared.open(url)
                                }
                            }) {
                                HStack(spacing: 12) {
                                    Image(systemName: "chevron.left.forwardslash.chevron.right")
                                        .foregroundColor(.orange)
                                        .font(.title3)
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Source Code")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        Text("GitHub Repository")
                                            .font(.subheadline)
                                            .foregroundColor(colorScheme == .dark ? .white : .black)
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: "arrow.up.right.square")
                                        .foregroundColor(.secondary)
                                        .font(.caption)
                                }
                                .padding(12)
                                .background(Color.orange.opacity(0.1))
                                .cornerRadius(10)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        .padding(20)
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
                                    iconColor: .blue,
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
                                    iconColor: .green,
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
                                    iconColor: .purple,
                                    title: "UK Company Compliance",
                                    subtitle: "Companies Act 2006 compliance"
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            Divider()
                                .padding(.leading, 62)
                            
                            Button(action: {
                                showCertificate = true
                                HapticManager.shared.light()
                            }) {
                                LegalDocRow(
                                    icon: "rosette",
                                    iconColor: .red,
                                    title: "Certificate of Incorporation",
                                    subtitle: "View official certificate (PDF)"
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    
                    // Compliance Badges
                    SettingsCard {
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Image(systemName: "shield.checkered")
                                    .font(.title2)
                                    .foregroundColor(.green)
                                
                                Text("Compliance & Standards")
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                    .foregroundColor(colorScheme == .dark ? .white : .black)
                            }
                            
                            Divider()
                                .padding(.vertical, 4)
                            
                            ComplianceBadge(
                                icon: "checkmark.seal.fill",
                                title: "UK GDPR Compliant",
                                description: "Full compliance with UK General Data Protection Regulation",
                                color: .blue
                            )
                            
                            ComplianceBadge(
                                icon: "lock.shield.fill",
                                title: "DPA 2018 Compliant",
                                description: "Adherence to Data Protection Act 2018",
                                color: .indigo
                            )
                            
                            ComplianceBadge(
                                icon: "building.columns.fill",
                                title: "Companies Act 2006",
                                description: "Registered and compliant with UK company law",
                                color: .purple
                            )
                            
                            ComplianceBadge(
                                icon: "globe.europe.africa.fill",
                                title: "Companies House",
                                description: "Active company registration in England and Wales",
                                color: .green
                            )
                        }
                        .padding(20)
                    }
                    
                    // Director Information
                    SettingsCard {
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Image(systemName: "person.crop.circle.badge.checkmark")
                                    .font(.title2)
                                    .foregroundColor(.orange)
                                
                                Text("Company Directors")
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                    .foregroundColor(colorScheme == .dark ? .white : .black)
                            }
                            
                            Divider()
                                .padding(.vertical, 4)
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Asad Khan")
                                    .font(.headline)
                                    .foregroundColor(colorScheme == .dark ? .white : .black)
                                
                                Label("Director", systemImage: "briefcase.fill")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Label("Appointed: 5 November 2025", systemImage: "calendar")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.orange.opacity(0.1))
                            .cornerRadius(10)
                        }
                        .padding(20)
                    }
                    
                    // App Version Info
                    VStack(spacing: 4) {
                        Text("RecipeFinder")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.6))
                        Text("Version 1.0.0 (Build 1)")
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.5))
                        Text("© 2025 RECIPEFINDER LIMITED")
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.5))
                    }
                    .padding(.top, 24)
                    .padding(.bottom, 40)
                }
                .padding(20)
            }
        }
        .navigationTitle("Legal Information")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .sheet(isPresented: $showPrivacyPolicy) {
            PrivacyPolicyView()
        }
        .sheet(isPresented: $showTermsOfService) {
            TermsOfServiceView()
        }
        .sheet(isPresented: $showCompanyCompliance) {
            CompanyComplianceView()
        }
        .sheet(isPresented: $showCertificate) {
            PDFViewerSheet(
                title: "Certificate of Incorporation",
                pdfName: "certicate_of_incorporation"
            )
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
                .foregroundColor(valueColor == .primary ? (colorScheme == .dark ? .white : .black) : valueColor)
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
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(iconColor)
                .font(.title3)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(colorScheme == .dark ? .white : .black)
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding(20)
    }
}

struct ComplianceBadge: View {
    let icon: String
    let title: String
    let description: String
    let color: Color
    
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 40, height: 40)
                
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(color)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(colorScheme == .dark ? .white : .black)
                
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
                    VStack(spacing: 16) {
                        Image(systemName: "doc.text.fill")
                            .font(.system(size: 60))
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
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.backgroundGradient(for: selectedTheme, colorScheme: colorScheme)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        Group {
                            Text("Privacy Policy")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(colorScheme == .dark ? .white : .black)
                            
                            Text("Last Updated: 5 November 2025")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Divider()
                            
                            SectionTitle("Overview")
                            BodyText("RecipeFinder is committed to protecting your privacy. This Privacy Policy explains how we handle information in our iOS application.")
                            
                            SectionTitle("Information Collection and Use")
                            BodyText("We do NOT collect, store, or transmit any personal information.")
                            
                            BodyText("RecipeFinder is designed with privacy as a core principle:")
                            
                            BulletPoint("100% Offline Functionality - All features work without internet connection")
                            BulletPoint("No Account Required - No registration, login, or user accounts")
                            BulletPoint("No Analytics - We don't track your usage or behavior")
                            BulletPoint("No Advertising - No third-party ad networks or tracking")
                            BulletPoint("No Cloud Storage - All data stored locally on your device")
                        }
                        
                        Group {
                            SectionTitle("Data Storage")
                            BodyText("All data is stored exclusively on your device using Core Data and UserDefaults. This includes:")
                            
                            BulletPoint("Recipes")
                            BulletPoint("Shopping Lists")
                            BulletPoint("Kitchen Inventory")
                            BulletPoint("Meal Plans")
                            BulletPoint("User Preferences")
                            BulletPoint("Favorites")
                            
                            SectionTitle("Your Rights")
                            BodyText("Since we don't collect any data, you have complete control:")
                            
                            BulletPoint("Export your data anytime from the Account tab")
                            BulletPoint("Delete all data from Settings > Data Management")
                            BulletPoint("Uninstall the app to remove all data from your device")
                        }
                        
                        Group {
                            SectionTitle("UK GDPR Compliance")
                            BodyText("RecipeFinder is fully compliant with UK GDPR and the Data Protection Act 2018. Since we don't collect any personal data, GDPR requirements don't apply.")
                            
                            SectionTitle("Changes to This Policy")
                            BodyText("We may update this Privacy Policy from time to time. We will notify you of any changes by posting the new Privacy Policy in the app.")
                            
                            SectionTitle("Contact Us")
                            BodyText("If you have questions about this Privacy Policy, contact us at:")
                            BodyText("AsadK47@users.noreply.github.com")
                        }
                    }
                    .padding(24)
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
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.backgroundGradient(for: selectedTheme, colorScheme: colorScheme)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        Group {
                            Text("Terms of Service")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(colorScheme == .dark ? .white : .black)
                            
                            Text("Last Updated: 5 November 2025")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Divider()
                            
                            SectionTitle("1. Acceptance of Terms")
                            BodyText("By downloading, installing, or using RecipeFinder, you agree to be bound by these Terms of Service.")
                            
                            SectionTitle("2. License")
                            BodyText("RECIPEFINDER LIMITED grants you a non-exclusive, non-transferable license to use this app for personal, non-commercial purposes.")
                            
                            SectionTitle("3. User Content")
                            BodyText("All recipes, notes, and data you create remain yours. We do not claim ownership of your content.")
                        }
                        
                        Group {
                            SectionTitle("4. Prohibited Uses")
                            BodyText("You agree not to:")
                            BulletPoint("Reverse engineer or decompile the app")
                            BulletPoint("Use the app for commercial purposes without permission")
                            BulletPoint("Attempt to circumvent any security features")
                            
                            SectionTitle("5. Disclaimer")
                            BodyText("The app is provided \"as is\" without warranties of any kind. Recipes are for informational purposes only. Always follow proper food safety guidelines.")
                            
                            SectionTitle("6. Limitation of Liability")
                            BodyText("RECIPEFINDER LIMITED shall not be liable for any damages arising from use of this app.")
                        }
                        
                        Group {
                            SectionTitle("7. Governing Law")
                            BodyText("These terms are governed by the laws of England and Wales.")
                            
                            SectionTitle("8. Contact")
                            BodyText("For questions about these Terms, contact:")
                            BodyText("RECIPEFINDER LIMITED")
                            BodyText("Company Number: 16833243")
                            BodyText("Email: AsadK47@users.noreply.github.com")
                        }
                    }
                    .padding(24)
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
                    VStack(alignment: .leading, spacing: 20) {
                        Group {
                            Text("UK Company Compliance")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(colorScheme == .dark ? .white : .black)
                            
                            Text("Companies Act 2006")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Divider()
                            
                            SectionTitle("Company Registration Details")
                            CompanyDetailRow(label: "Legal Name", value: "RECIPEFINDER LIMITED")
                            CompanyDetailRow(label: "Company Number", value: "16833243")
                            CompanyDetailRow(label: "Jurisdiction", value: "England and Wales")
                            CompanyDetailRow(label: "Incorporation Date", value: "5 November 2025")
                            CompanyDetailRow(label: "Company Type", value: "Private Limited Company by Shares")
                            CompanyDetailRow(label: "Status", value: "Active")
                        }
                        
                        Group {
                            SectionTitle("Directors")
                            BodyText("Director: Asad Khan")
                            BodyText("Appointed: 5 November 2025")
                            
                            SectionTitle("Director Responsibilities")
                            BodyText("Under the Companies Act 2006, directors must:")
                            BulletPoint("Act within powers (s.171)")
                            BulletPoint("Promote the success of the company (s.172)")
                            BulletPoint("Exercise independent judgment (s.173)")
                            BulletPoint("Exercise reasonable care, skill and diligence (s.174)")
                            BulletPoint("Avoid conflicts of interest (s.175)")
                            BulletPoint("Not accept benefits from third parties (s.176)")
                            BulletPoint("Declare interest in proposed transactions (s.177)")
                        }
                        
                        Group {
                            SectionTitle("Compliance Status")
                            BulletPoint("✅ Companies House Registration: Complete")
                            BulletPoint("✅ Certificate of Incorporation: Issued")
                            BulletPoint("✅ UK GDPR Compliance: Achieved")
                            BulletPoint("✅ DPA 2018 Compliance: Achieved")
                            BulletPoint("✅ Privacy Policy: Published")
                            BulletPoint("✅ Terms of Service: Published")
                            
                            SectionTitle("Registered Office")
                            BodyText("The company's registered office is located in England and Wales as filed with Companies House.")
                            
                            SectionTitle("More Information")
                            BodyText("For complete compliance documentation and company records, visit the Companies House website with our company number: 16833243")
                        }
                    }
                    .padding(24)
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
            .foregroundColor(colorScheme == .dark ? .white : .black)
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
            .foregroundColor(colorScheme == .dark ? .white.opacity(0.9) : .black.opacity(0.8))
            .fixedSize(horizontal: false, vertical: true)
    }
}

struct BulletPoint: View {
    let text: String
    @Environment(\.colorScheme) var colorScheme
    
    init(_ text: String) {
        self.text = text
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text("•")
                .foregroundColor(.secondary)
            Text(text)
                .font(.body)
                .foregroundColor(colorScheme == .dark ? .white.opacity(0.9) : .black.opacity(0.8))
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
                .foregroundColor(colorScheme == .dark ? .white : .black)
        }
        .padding(.vertical, 2)
    }
}

#Preview {
    NavigationStack {
        LegalInformationView()
    }
}
