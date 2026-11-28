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

                    // Badge wording mirrors Privacy Policy 10.1 ("designed to comply"); version and © live in About.
                    SettingsCard {
                        VStack(alignment: .leading, spacing: AppTheme.spacing16) {
                            HStack {
                                Image(systemName: "shield.checkered")
                                    .font(.title2)
                                    .adaptiveForegroundColor()

                                Text("Data Protection")
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                    .adaptiveForegroundColor()
                            }

                            Divider()
                                .padding(.vertical, AppTheme.spacing4)

                            ComplianceBadge(
                                icon: "lock.shield.fill",
                                title: "UK GDPR",
                                description: "Designed to comply with the UK General Data Protection Regulation",
                                color: AppTheme.textColor()
                            )

                            ComplianceBadge(
                                icon: "lock.shield.fill",
                                title: "Data Protection Act 2018",
                                description: "Designed to comply with the Data Protection Act 2018",
                                color: AppTheme.textColor()
                            )
                        }
                        .padding(AppTheme.spacing24)
                    }
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
