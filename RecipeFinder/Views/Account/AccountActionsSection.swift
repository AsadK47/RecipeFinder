import SwiftUI

/// The account actions on the Account screen: (disabled) Link Apple ID, configure
/// biometrics, sign out, and delete account. Extracted from `AccountView`.
struct AccountActionsSection: View {
    let showLinkAppleID: Bool
    let biometricsAvailable: Bool
    let biometricType: String
    let selectedTheme: AppTheme.ThemeType
    let cardStyle: CardStyle
    let colorScheme: ColorScheme
    let onSignOut: () -> Void
    let onDeleteAccount: () -> Void

    var body: some View {
        VStack(spacing: AppTheme.spacing12) {
            if showLinkAppleID {
                VStack(spacing: AppTheme.spacing8) {
                    Button {
                        HapticManager.shared.light()
                    } label: {
                        HStack(spacing: AppTheme.spacing12) {
                            Image(systemName: "applelogo")
                                .font(.system(size: AppTheme.fontSize18, weight: .semibold))
                            Text("Link Apple ID")
                                .font(.body)
                                .fontWeight(.semibold)
                        }
                        .adaptiveForegroundColor(opacity: AppTheme.glassLightOpacity)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppTheme.spacing16)
                        .background {
                            if cardStyle == .solid {
                                RoundedRectangle(cornerRadius: AppTheme.cornerRadius12)
                                    .fill(Color.black.opacity(AppTheme.shadowDarkOpacity))
                            } else {
                                RoundedRectangle(cornerRadius: AppTheme.cornerRadius12)
                                    .fill(Color.black.opacity(AppTheme.lowEmphasisOpacity))
                            }
                        }
                        .overlay(
                            RoundedRectangle(cornerRadius: AppTheme.cornerRadius12)
                                .stroke(Color.orange.opacity(AppTheme.lowEmphasisOpacity), lineWidth: 1)
                        )
                    }
                    .disabled(true)
                    
                    HStack(spacing: AppTheme.spacing4) {
                        Image(systemName: "wrench.and.screwdriver.fill")
                            .font(.system(size: AppTheme.fontSize11))
                        Text("Under Construction • Please Wait Patiently")
                            .font(.system(size: AppTheme.fontSize11, weight: .medium))
                    }
                    .foregroundStyle(.orange.opacity(AppTheme.highEmphasisOpacity))
                }
            }
            
            if biometricsAvailable {
                NavigationLink(destination: PrivacySettingsView()) {
                    HStack(spacing: AppTheme.spacing12) {
                        Image(systemName: biometricType == "Face ID" ? "faceid" : "touchid")
                            .font(.system(size: AppTheme.fontSize18, weight: .semibold))
                        Text("Configure \(biometricType)")
                            .font(.body)
                            .fontWeight(.semibold)
                    }
                    .adaptiveForegroundColor()
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppTheme.spacing16)
                    .background {
                        if cardStyle == .solid {
                            RoundedRectangle(cornerRadius: AppTheme.cornerRadius12)
                                .fill(AppTheme.accentColor(for: selectedTheme).opacity(AppTheme.highEmphasisOpacity))
                        } else {
                            RoundedRectangle(cornerRadius: AppTheme.cornerRadius12)
                                .fill(AppTheme.accentColor(for: selectedTheme).opacity(AppTheme.shadowDarkOpacity))
                        }
                    }
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.cornerRadius12)
                            .stroke(AppTheme.accentColor(for: selectedTheme).opacity(AppTheme.shadowDarkOpacity), lineWidth: 1)
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            Button {
                onSignOut()
            } label: {
                Text("Sign Out")
                    .font(.body)
                    .fontWeight(.semibold)
                    .foregroundStyle(AppTheme.error)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppTheme.spacing16)
                    .background {
                        if cardStyle == .solid {
                            RoundedRectangle(cornerRadius: AppTheme.cornerRadius12)
                                .fill(colorScheme == .dark ? Color(white: AppTheme.cardDarkOpacity) : Color.white)
                        } else {
                            RoundedRectangle(cornerRadius: AppTheme.cornerRadius12)
                                .fill(.ultraThinMaterial)
                        }
                    }
            }
            
            Button {
                onDeleteAccount()
                } label: {
                    Text("Delete Account")
                        .font(.body)
                        .fontWeight(.semibold)
                        .foregroundStyle(AppTheme.error)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppTheme.spacing16)
                        .background {
                            if cardStyle == .solid {
                                RoundedRectangle(cornerRadius: AppTheme.cornerRadius12)
                                    .fill(colorScheme == .dark ? Color(white: AppTheme.cardDarkOpacity) : Color.white)
                            } else {
                                RoundedRectangle(cornerRadius: AppTheme.cornerRadius12)
                                    .fill(.ultraThinMaterial)
                            }
                        }
                }
                .buttonStyle(PlainButtonStyle())
        }
    }
}
