import SwiftUI

struct LegalInformationView: View {
    @Environment(\.colorScheme) var colorScheme
    @State private var showPrivacyPolicy = false
    @State private var showTermsOfService = false
    @State private var showCompanyCompliance = false

    var body: some View {
        ZStack {
            AppBackground()

            ScrollView {
                VStack(spacing: AppTheme.spacing32) {
                    SettingsCard {
                        VStack(alignment: .leading, spacing: AppTheme.spacing16) {
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
                                .padding(.vertical, AppTheme.spacing4)

                            CompanyInfoRow(label: "Legal Name", value: "RECIPEFINDER LIMITED")
                            CompanyInfoRow(label: "Company Number", value: "16833243")
                            CompanyInfoRow(label: "Registered", value: "England and Wales")
                            CompanyInfoRow(label: "Incorporation Date", value: "5 November 2025")
                            CompanyInfoRow(label: "Company Type", value: "Private Limited Company")
                            CompanyInfoRow(label: "Status", value: "Active", valueColor: AppTheme.success)
                        }
                        .padding(AppTheme.spacing24)
                    }

                    LegalContactCard()

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
                                .padding(.leading, AppTheme.spacing62)

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
                                .padding(.leading, AppTheme.spacing62)

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

                    SettingsCard {
                        VStack(alignment: .leading, spacing: AppTheme.spacing16) {
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
                                .padding(.vertical, AppTheme.spacing4)

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
                        .padding(AppTheme.spacing24)
                    }

                    SettingsCard {
                        VStack(alignment: .leading, spacing: AppTheme.spacing16) {
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
                                .padding(.vertical, AppTheme.spacing4)

                            VStack(alignment: .leading, spacing: AppTheme.spacing8) {
                                Text("Asad Khan")
                                    .font(.headline)
                                    .adaptiveForegroundColor()

                                Label("Director", systemImage: "briefcase.fill")
                                    .font(.caption)
                                    .adaptiveSecondaryForeground()

                                Label("Appointed: 5 November 2025", systemImage: "calendar")
                                    .font(.caption)
                                    .adaptiveSecondaryForeground()
                            }
                            .padding(AppTheme.spacing12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.white.opacity(colorScheme == .dark ? AppTheme.dividerOpacity : 0.05))
                            .cornerRadius(AppTheme.cornerRadius12)
                        }
                        .padding(AppTheme.spacing24)
                    }

                    VStack(spacing: AppTheme.spacing4) {
                        Text("RecipeFinder")
                            .font(.caption)
                            .adaptiveForegroundColor(opacity: AppTheme.mediumEmphasisOpacity)
                        Text("Version 1.0.0 (Build 1)")
                            .font(.caption2)
                            .adaptiveForegroundColor(opacity: AppTheme.glassLightOpacity)
                        Text("© 2025 RECIPEFINDER LIMITED")
                            .font(.caption2)
                            .adaptiveForegroundColor(opacity: AppTheme.glassLightOpacity)
                    }
                    .padding(.top, AppTheme.spacing24)
                    .padding(.bottom, AppTheme.spacing40)
                }
                .padding(AppTheme.spacing24)
            }
        }
        .appNavigationTitle("Legal Information")
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

#Preview {
    NavigationStack {
        LegalInformationView()
    }
}
