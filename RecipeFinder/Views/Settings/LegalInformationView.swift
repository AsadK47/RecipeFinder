import SwiftUI

struct LegalInformationView: View {
    @State private var showPrivacyPolicy = false
    @State private var showTermsOfService = false

    var body: some View {
        ZStack {
            AppBackground()

            ScrollView {
                VStack(spacing: AppTheme.spacing32) {
                    LegalContactCard()

                    SettingsCard {
                        VStack(spacing: 0) {
                            Button(action: {
                                showPrivacyPolicy = true
                                HapticManager.shared.light()
                            }) {
                                LegalDocRow(
                                    icon: "hand.raised.fill",
                                    iconColor: AppTheme.textColor(),
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
                                    iconColor: AppTheme.textColor(),
                                    title: "Terms of Service",
                                    subtitle: "Terms and conditions of use"
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
                                color: AppTheme.textColor()
                            )

                            ComplianceBadge(
                                icon: "lock.shield.fill",
                                title: "Data Protection Act 2018",
                                description: "Adherence to UK data protection legislation",
                                color: AppTheme.textColor()
                            )
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
                        Text("© 2025 Asad Ullah Khan")
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
        .sheet(isPresented: $showPrivacyPolicy) {
            PrivacyPolicyView()
        }
        .sheet(isPresented: $showTermsOfService) {
            TermsOfServiceView()
        }
    }
}

#Preview {
    NavigationStack {
        LegalInformationView()
    }
}
