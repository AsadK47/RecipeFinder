import SwiftUI

/// Biometric sign-in and privacy policy access.
struct PrivacySettingsView: View {
    @Environment(\.auth) private var authManager
    @AppStorage("biometricsEnabled") private var biometricsEnabled: Bool = false
    @State private var showPrivacyPolicy = false
    @State private var showBiometricError = false
    @State private var biometricErrorMessage = ""

    var body: some View {
        SettingsScreen("Privacy") {
            if authManager.biometricsAvailable {
                VStack(spacing: AppTheme.spacing8) {
                    SettingsSectionHeader(title: "Security")

                    SettingsCard {
                        SettingsToggleRow(
                            icon: authManager.biometricType == "Face ID" ? "faceid" : "touchid",
                            iconColor: .green,
                            title: authManager.biometricType,
                            subtitle: "Sign in with \(authManager.biometricType) instead of password",
                            isOn: Binding(
                                get: { biometricsEnabled },
                                set: { newValue in
                                    if newValue {
                                        enableBiometrics()
                                    } else {
                                        biometricsEnabled = false
                                        HapticManager.shared.light()
                                    }
                                }
                            )
                        )
                    }
                }
            }

            SettingsSection(title: "Policies", items: [
                .init(
                    row: SettingsRow(icon: "hand.raised.fill", iconColor: .blue, title: "Privacy Policy", subtitle: "View our privacy and data practices"),
                    action: {
                        showPrivacyPolicy = true
                        HapticManager.shared.light()
                    }
                )
            ])
        }
        .sheet(isPresented: $showPrivacyPolicy) {
            PrivacyPolicyView()
        }
        .alert("Biometric Error", isPresented: $showBiometricError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(biometricErrorMessage)
        }
    }

    private func enableBiometrics() {
        Task {
            do {
                try await authManager.authenticateWithBiometrics()
                DispatchQueue.main.async {
                    biometricsEnabled = true
                    HapticManager.shared.success()
                }
            } catch {
                DispatchQueue.main.async {
                    biometricErrorMessage = error.localizedDescription
                    showBiometricError = true
                    HapticManager.shared.error()
                }
            }
        }
    }
}

struct PrivacyInfoRow: View {
    let icon: String
    var iconColor: Color = .green
    let title: String
    let description: String

    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        HStack(alignment: .top, spacing: AppTheme.spacing16) {
            ZStack {
                Circle()
                    .fill(iconColor.opacity(AppTheme.cardDarkOpacity))
                    .frame(width: 40, height: AppTheme.height40)

                Image(systemName: icon)
                    .font(.system(size: AppTheme.fontSize18, weight: .semibold))
                    .foregroundColor(iconColor)
            }

            VStack(alignment: .leading, spacing: AppTheme.spacing4) {
                Text(title)
                    .font(.body)
                    .fontWeight(.semibold)
                    .adaptiveForegroundColor()

                Text(description)
                    .font(.caption)
                    .adaptiveSecondaryForeground()
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

#Preview {
    NavigationStack {
        PrivacySettingsView()
    }
}
