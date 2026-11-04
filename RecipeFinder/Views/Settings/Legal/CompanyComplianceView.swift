import SwiftUI

struct CompanyComplianceView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: AppTheme.spacing24) {
                        Group {
                            Text("UK Company Compliance")
                                .font(.system(size: AppTheme.fontSize32, weight: .bold))
                                .adaptiveForegroundColor()
                            
                            Text("Companies Act 2006")
                                .font(.caption)
                                .adaptiveSecondaryForeground()
                            
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
                            LegalBulletPoint("Section 171: Duty to act within powers")
                            LegalBulletPoint("Section 172: Duty to promote the success of the company")
                            LegalBulletPoint("Section 173: Duty to exercise independent judgment")
                            LegalBulletPoint("Section 174: Duty to exercise reasonable care, skill and diligence")
                            LegalBulletPoint("Section 175: Duty to avoid conflicts of interest")
                            LegalBulletPoint("Section 176: Duty not to accept benefits from third parties")
                            LegalBulletPoint("Section 177: Duty to declare interest in proposed transaction or arrangement")
                        }
                        
                        Group {
                            SectionTitle("4. Regulatory Compliance")
                            BodyText("4.1 The Company maintains compliance with:")
                            LegalBulletPoint("Companies Act 2006 (United Kingdom)")
                            LegalBulletPoint("UK General Data Protection Regulation (UK GDPR)")
                            LegalBulletPoint("Data Protection Act 2018")
                            LegalBulletPoint("Copyright, Designs and Patents Act 1988")
                            LegalBulletPoint("Consumer Rights Act 2015")
                            
                            SectionTitle("5. Registered Office")
                            BodyText("5.1 The Company's registered office address is maintained on file with Companies House in accordance with Section 86 of the Companies Act 2006.")
                            
                            SectionTitle("6. Annual Requirements")
                            BodyText("6.1 The Company shall comply with all annual filing requirements, including:")
                            LegalBulletPoint("Confirmation Statement (Section 853A)")
                            LegalBulletPoint("Annual Accounts (Sections 441-442)")
                            LegalBulletPoint("Corporation Tax Return (as required by HMRC)")
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
